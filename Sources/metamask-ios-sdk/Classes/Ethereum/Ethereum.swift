//
//  Ethereum.swift
//

import UIKit
import Combine
import Foundation

typealias EthereumPublisher = AnyPublisher<Any, RequestError>

protocol EthereumEventsDelegate: AnyObject {
    func chainIdChanged(_ chainId: String)
    func accountChanged(_ account: String)
}

public class Ethereum {
    static let CONNECTION_ID = TimestampGenerator.timestamp()
    static let BATCH_CONNECTION_ID = TimestampGenerator.timestamp()
    
    var submittedRequests: [String: SubmittedRequest] = [:]
    private let queue = DispatchQueue(label: "submittedRequests.queue")
    
    private var cancellables: Set<AnyCancellable> = []
    private let cancellablesLock = NSRecursiveLock()

    let readOnlyRPCProvider: ReadOnlyRPCProvider

    weak var delegate: EthereumEventsDelegate?

    var connected: Bool = false

    /// The active/selected MetaMask account chain
    var chainId: String = ""

    /// The active/selected MetaMask account address
    var account: String = ""

    let store: SecureStore
    var appMetadata: AppMetadata?
    var commClient: CommClient
    public var transport: Transport
    var commClientFactory: CommClientFactory
    
    var track: ((Event, [String: Any]) -> Void)?
    private let ACCOUNT_KEY = "ACCOUNT_KEY"
    private let CHAINID_KEY = "CHAIN_ID_KEY"
    

    private init(transport: Transport,
                 store: SecureStore,
                 commClientFactory: CommClientFactory,
                 readOnlyRPCProvider: ReadOnlyRPCProvider,
                 track: @escaping ((Event, [String: Any]) -> Void)) {
        self.track = track
        self.store = store
        self.transport = transport
        
        switch transport {
        case .socket:
            self.commClient = commClientFactory.socketClient()
        case .deeplinking(let dappScheme):
            self.commClient = commClientFactory.deeplinkClient(dappScheme: dappScheme)
        }
        
        self.commClientFactory = commClientFactory
        self.readOnlyRPCProvider = readOnlyRPCProvider
        self.commClient.trackEvent = trackEvent
        self.commClient.handleResponse = handleMessage
        self.commClient.onClientsTerminated = terminateConnection
        fetchCachedSession()
    }

    public static func shared(transport: Transport,
                              store: SecureStore,
                              commClientFactory: CommClientFactory,
                              readOnlyRPCProvider: ReadOnlyRPCProvider,
                              trackEvent: @escaping ((Event, [String: Any]) -> Void)) -> Ethereum {
        guard let ethereum = EthereumWrapper.shared.ethereum else {
            let ethereum = Ethereum(
                transport: transport,
                store: store,
                commClientFactory: commClientFactory,
                readOnlyRPCProvider: readOnlyRPCProvider,
                track: trackEvent)
            EthereumWrapper.shared.ethereum = ethereum
            return ethereum
        }
        return ethereum
    }
    
    private func fetchCachedSession() {
        if
            let account = store.string(for: ACCOUNT_KEY),
            let chainId = store.string(for: CHAINID_KEY)
        {
            self.account = account
            self.chainId = chainId
            connected = true
            delegate?.accountChanged(account)
            delegate?.chainIdChanged(chainId)
        }
    }

    @discardableResult
    func updateTransportLayer(_ transport: Transport) -> Ethereum {
        
        self.transport = transport

        switch transport {
        case .deeplinking(let dappScheme):
            commClient = commClientFactory.deeplinkClient(dappScheme: dappScheme)
        case .socket:
            commClient = commClientFactory.socketClient()
            commClient.onClientsTerminated = terminateConnection
        }
        commClient.appMetadata = appMetadata
        
        fetchCachedSession()

        commClient.trackEvent = trackEvent
        commClient.handleResponse = handleMessage
        return self
    }

    private func trackEvent(event: Event, parameters: [String: Any]) {
        track?(event, parameters)
    }

    func updateMetadata(_ metadata: AppMetadata) {
        appMetadata = metadata
        commClient.appMetadata = metadata
    }
    
    func addRequest(_ submittedRequest: SubmittedRequest, id: String) {
        queue.async { [weak self] in
            self?.submittedRequests[id] = submittedRequest
        }
    }
    
    func getAllRequests() -> [String: SubmittedRequest] {
        return queue.sync { [weak self] in
            return self?.submittedRequests ?? [:]
        }
    }

    func getRequest(id: String) -> SubmittedRequest? {
        return queue.sync { [weak self] in
            return self?.submittedRequests[id]
        }
    }

    func removeRequest(id: String) {
        queue.async { [weak self] in
            self?.submittedRequests.removeValue(forKey: id)
        }
    }
    
    func removeAllRequests() {
        queue.async { [weak self] in
            self?.submittedRequests.removeAll()
        }
    }
    
    private func syncCancellables() -> Set<AnyCancellable> {
        cancellablesLock.sync {
            return cancellables
        }
    }

    // MARK: Session Management

    @discardableResult
    /// Connect to MetaMask mobile wallet. This method must be called first and once, to establish a connection before any requests can be made
    /// - Returns: A Combine publisher that will emit a connection result or error once a response is received
    func connect() -> EthereumPublisher? {
        commClient.connect(with: nil)
        connected = true

        if commClient is SocketClient {
            return requestAccounts()
        }

        let submittedRequest = SubmittedRequest(method: "")
        addRequest(submittedRequest, id: Ethereum.CONNECTION_ID)
        let publisher = getRequest(id: Ethereum.CONNECTION_ID)?.publisher

        return publisher
    }
    
    func performAsyncOperation<T>(_ publisher: EthereumPublisher?, defaultValue: T) async -> Result<T, RequestError> {
        guard let publisher = publisher else {
            return .failure(.genericError)
        }

        return await withCheckedContinuation { continuation in
            let cancellable = publisher
                .tryMap { output in
                    // remove nil and NSNUll values in result
                    if  let resultArray = output as? [Any?] {
                        let resultItems = resultArray
                            .filter({ !($0 is NSNull) })
                            .compactMap({ $0 })
                        guard let result = resultItems as? T else {
                            return defaultValue
                        }
                        return result
                    }
                    guard let result = output as? T else {
                        return defaultValue
                    }
                    return result
                }
                .mapError { error in
                    error as? RequestError ?? RequestError.responseError
                }
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }, receiveValue: { result in
                    continuation.resume(returning: .success(result))
                })
            
            cancellablesLock.sync {
                cancellables.insert(cancellable)
            }
        }
    }
    
    func request(_ req: any RPCRequest) async -> Result<String, RequestError> {
        let publisher = performRequest(req)
        return await performAsyncOperation(publisher, defaultValue: String()) as Result<String, RequestError>
    }
    
    func request(_ req: any RPCRequest) async -> Result<[String], RequestError> {
        let publisher = performRequest(req)
        return await performAsyncOperation(publisher, defaultValue: [String]()) as Result<[String], RequestError>
    }
    
    @discardableResult
    func connect() async -> Result<[String], RequestError> {
        await performAsyncOperation(connect(), defaultValue: []) as Result<[String], RequestError>
    }

    func connectAndSign(message: String) -> EthereumPublisher? {
        let connectSignRequest = EthereumRequest(
            method: .metaMaskConnectSign,
            params: [message]
        )
        connected = true
        
        let requestJson = connectSignRequest.toJsonString() ?? ""

        if commClient is SocketClient {
            commClient.connect(with: requestJson)
            return performRequest(connectSignRequest)
        }

        let submittedRequest = SubmittedRequest(method: connectSignRequest.method)
        addRequest(submittedRequest, id: connectSignRequest.id)
        let publisher = getRequest(id: connectSignRequest.id)?.publisher

        commClient.connect(with: requestJson)

        return publisher
    }

    func connectAndSign(message: String) async -> Result<String, RequestError> {
        await performAsyncOperation(connectAndSign(message: message), defaultValue: String()) as Result<String, RequestError>
    }

    func connectWith<T: CodableData>(_ req: EthereumRequest<T>) -> EthereumPublisher? {
        let params: [EthereumRequest] = [req]
        let connectWithRequest = EthereumRequest(
            method: EthereumMethod.metamaskConnectWith.rawValue,
            params: params
        )
        connected = true

        switch transport {
        case .socket:

            // React Native SDK has request params as Data
            if let paramsData = req.params as? Data {
                let reqJson = String(data: paramsData, encoding: .utf8)?.trimEscapingChars() ?? ""
                let requestItem: EthereumRequest = EthereumRequest(
                    id: req.id,
                    method: req.method,
                    params: reqJson
                )

                let connectWithParams = [requestItem]
                let connectRequest = EthereumRequest(
                    id: connectWithRequest.id,
                    method: connectWithRequest.method,
                    params: connectWithParams
                )
                commClient.connect(with: connectRequest.toJsonString())
                return performRequest(connectRequest)
            } else {
                commClient.connect(with: connectWithRequest.toJsonString())
                return performRequest(connectWithRequest)
            }
        case .deeplinking:
            let submittedRequest = SubmittedRequest(method: connectWithRequest.method)
            addRequest(submittedRequest, id: connectWithRequest.id)
            let publisher = getRequest(id: connectWithRequest.id)?.publisher

            // React Native SDK has request params as Data
            if let paramsData = req.params as? Data {
                do {
                    let params = try JSONSerialization.jsonObject(with: paramsData, options: [])

                    let requestDict: [String: Any] = [
                        "id": req.id,
                        "method": req.method,
                        "params": params
                        ]

                    let jsonData = try JSONSerialization.data(withJSONObject: requestDict)
                    let jsonParams = try JSONSerialization.jsonObject(with: jsonData, options: [])

                    let connectWithParams = [jsonParams]

                    let connectWithDict: [String: Any] = [
                        "id": connectWithRequest.id,
                        "method": connectWithRequest.method,
                        "params": connectWithParams
                        ]

                    let connectWithJson = json(from: connectWithDict) ?? ""

                    commClient.connect(with: connectWithJson)
                } catch {
                    Logging.error("Ethereum:: error: \(error.localizedDescription)")
                }
            } else {
                let requestJson = connectWithRequest.toJsonString() ?? ""
                commClient.connect(with: requestJson)
            }
            return publisher
        }
    }
    
    func connectWith<T: CodableData>(_ req: EthereumRequest<T>) async -> Result<String, RequestError> {
        return await performAsyncOperation(connectWith(req), defaultValue: String()) as Result<String, RequestError>
    }

    // MARK: Convenience Methods

    func getChainId() async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethChainId, params: [String]())
    }

    func getEthAccounts() async -> Result<[String], RequestError> {
        await ethereumRequest(method: .ethAccounts, params: [String]())
    }

    func getEthGasPrice() async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethGasPrice)
    }

    func getEthBalance(address: String, block: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethGetBalance, params: [address, block])
    }

    func getEthBlockNumber() async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethBlockNumber)
    }

    func getEthEstimateGas() async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethEstimateGas)
    }

    func getWeb3ClientVersion() async -> Result<String, RequestError> {
        await ethereumRequest(method: .web3ClientVersion, params: [String]())
    }

    func personalSign(message: String, address: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .personalSign, params: [address, message])
    }

    func signTypedDataV4(typedData: String, address: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethSignTypedDataV4, params: [address, typedData])
    }

    func sendTransaction(from: String, to: String, value: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethSendTransaction, params: [
            [
                "from": from,
                "to": to,
                "value": value
            ]
        ])
    }

    func sendRawTransaction(signedTransaction: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethSendRawTransaction, params: [signedTransaction])
    }

    func getBlockTransactionCountByNumber(blockNumber: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethGetBlockTransactionCountByNumber, params: [blockNumber])
    }

    func getBlockTransactionCountByHash(blockHash: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethGetBlockTransactionCountByHash, params: [blockHash])
    }

    func getTransactionCount(address: String, tagOrblockNumber: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethGetTransactionCount, params: [address, tagOrblockNumber])
    }

    func addEthereumChain(chainId: String,
                          chainName: String,
                          rpcUrls: [String],
                          iconUrls: [String]?,
                          blockExplorerUrls: [String]?,
                          nativeCurrency: NativeCurrency) async -> Result<String, RequestError> {

        return await ethereumRequest(method: .addEthereumChain, params: [
                AddChainParameters(
                    chainId: chainId,
                    chainName: chainName,
                    rpcUrls: rpcUrls,
                    iconUrls: iconUrls,
                    blockExplorerUrls: blockExplorerUrls,
                    nativeCurrency: nativeCurrency
                )
        ])
    }

    func switchEthereumChain(chainId: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .switchEthereumChain, params: [
            ["chainId": chainId]
        ])
    }

    private func ethereumRequest<T: CodableData>(method: EthereumMethod, params: T = "") async -> Result<String, RequestError> {
        let ethRequest = EthereumRequest(method: method, params: params)
        return await request(ethRequest)
    }

    private func ethereumRequest<T: CodableData>(method: EthereumMethod, params: T = "") async -> Result<[String], RequestError> {
        let ethRequest = EthereumRequest(method: method, params: params)
        return await request(ethRequest)
    }

    /// Disconnect dapp
    func disconnect() {
        connected = false
        commClient.disconnect()
    }

    func clearSession() {
        updateChainId("")
        updateAccount("")
        store.deleteData(for: ACCOUNT_KEY)
        store.deleteData(for: CHAINID_KEY)
        connected = false
        commClient.clearSession()
    }

    func terminateConnection() {
        if connected {
            track?(.connectionTerminated, [:])
        }

        let error = RequestError(from: ["message": "The connection request has been rejected"])
        getAllRequests().forEach { key, _ in
            getRequest(id: key)?.error(error)
        }
        removeAllRequests()
        clearSession()
    }

    // MARK: Request Sending

    func sendRequest(_ request: any RPCRequest) {
        if
            EthereumMethod.isReadOnly(request.methodType),
            readOnlyRPCProvider.supportsChain(chainId) {
            Task {
                let readOnlyRequest = EthereumRequest(
                    id: request.id,
                    method: request.method
                )
                var params: Any = request.params
                
                if
                    let paramsData = request.params as? Data,
                    let json = try? JSONSerialization.jsonObject(with: paramsData, options: []) {
                    params = json
                }
                
                if let result = await readOnlyRPCProvider.sendRequest(
                    readOnlyRequest,
                    params: params,
                    chainId: chainId,
                    appMetadata: commClient.appMetadata ?? AppMetadata(name: "", url: "")) {
                    sendResult(result, id: request.id)
                }
            }
        } else {
            track?(.sdkRpcRequest, [
                "from": "mobile",
                "method": request.method
            ])

            switch transport {
            case .socket:
                // React Native SDK has request params as Data
                if let paramsData = request.params as? Data {
                    do {
                        let params = try JSONSerialization.jsonObject(with: paramsData, options: [])

                        let requestDict: [String: Any] = [
                            "id": request.id,
                            "method": request.method,
                            "params": params
                            ]

                        let requestJson = json(from: requestDict) ?? ""

                        commClient.sendMessage(requestJson, encrypt: true, options: [:])
                    } catch {
                        Logging.error("Ethereum:: error: \(error.localizedDescription)")
                    }
                } else {
                    commClient.sendMessage(request, encrypt: true, options: [:])
                }

                let authorise = EthereumMethod.requiresAuthorisation(request.methodType)
                let skipAuthorisation = request.methodType == .ethRequestAccounts && !account.isEmpty

                if authorise && !skipAuthorisation {
                    commClient.requestAuthorisation()
                }

            case .deeplinking:
                // React Native SDK has request params as Data
                if let paramsData = request.params as? Data {
                    do {
                        let params = try JSONSerialization.jsonObject(with: paramsData, options: [])

                        let requestDict: [String: Any] = [
                            "id": request.id,
                            "method": request.method,
                            "params": params
                            ]

                        let requestJson = json(from: requestDict) ?? ""

                        commClient.sendMessage(requestJson, encrypt: true, options: ["account": account, "chainId": chainId])
                    } catch {
                        Logging.error("Ethereum:: error: \(error.localizedDescription)")
                        return
                    }
                } else {
                    guard let requestJson = request.toJsonString() else {
                        Logging.error("Ethereum:: could not convert request to JSON: \(request)")
                            return
                        }

                    commClient.sendMessage(requestJson, encrypt: true, options: ["account": account, "chainId": chainId])
                }
            }
        }
    }

    @discardableResult
    private func requestAccounts() -> EthereumPublisher? {
        let requestAccountsRequest = EthereumRequest(
            id: Ethereum.CONNECTION_ID,
            method: .ethRequestAccounts
        )

        let submittedRequest = SubmittedRequest(method: requestAccountsRequest.method)
        addRequest(submittedRequest, id: requestAccountsRequest.id)
        let publisher = getRequest(id: requestAccountsRequest.id)?.publisher

        commClient.addRequest { [weak self] in
            self?.sendRequest(requestAccountsRequest)
        }

        return publisher
    }

    @discardableResult
    /// Performs and Ethereum remote procedural call (RPC)
    /// - Parameter request: The RPC request. It's `parameters` need to conform to `CodableData`
    /// - Returns: A Combine publisher that will emit a result or error once a response is received
    func performRequest(_ request: any RPCRequest) -> EthereumPublisher? {
        let isConnectMethod = EthereumMethod.isConnectMethod(request.methodType)
        
        if !connected && !isConnectMethod && account.isEmpty {
            if request.methodType == .ethRequestAccounts {
                commClient.connect(with: nil)
                connected = true
                return requestAccounts()
            }
            
            return RequestError.failWithError(.connectError)
        } else {
            let id = request.id
            let submittedRequest = SubmittedRequest(method: request.method)
            addRequest(submittedRequest, id: id)
            
            let publisher = getRequest(id: id)?.publisher

            if connected || !account.isEmpty {
                connected = true
                sendRequest(request)
            } else {
                commClient.connect(with: nil)
                connected = true
                commClient.addRequest { [weak self] in
                    self?.sendRequest(request)
                }
            }
            return publisher
        }
    }
    
    private func isRequestParamData<T: CodableData>(_ request: EthereumRequest<T>?) -> Bool {
        if let content = request?.params as? [Any], !content.isEmpty {
            return content.first is Data
        }
        return request?.params is Data
    }

    func batchRequest<T: CodableData>(_ requests: [EthereumRequest<T>]) async -> Result<[String], RequestError> {

        // React Native SDK has request params as Data
        if (isRequestParamData(requests.first)) {
            var requestDicts: [[String: Any]] = []

            for request in requests {

                if let paramData = request.params as? Data {
                    do {
                        let requestParams = try JSONSerialization.jsonObject(with: paramData, options: [])

                        let dict: [String: Any] = [
                            "id": request.id,
                            "method": request.method,
                            "params": requestParams
                        ]
                        requestDicts.append(dict)
                    } catch {
                        Logging.error("Ethereum:: error: \(error.localizedDescription)")
                        return .failure(RequestError(from: ["message": error.localizedDescription]))
                    }
                }
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: requestDicts)
                let batchReq = EthereumRequest(
                    method: EthereumMethod.metamaskBatch.rawValue,
                    params: jsonData)

                return await performAsyncOperation(performRequest(batchReq), defaultValue: [String]()) as Result<[String], RequestError>
            } catch {
                Logging.error("Ethereum:: error: \(error.localizedDescription)")
                return .failure(RequestError(from: ["message": error.localizedDescription]))
            }
        } else {
            let batchRequest = EthereumRequest(
                method: EthereumMethod.metamaskBatch.rawValue,
                params: requests)

            return await performAsyncOperation(performRequest(batchRequest), defaultValue: [String]()) as Result<[String], RequestError>
        }
    }

    // MARK: Request Receiving
    private func updateChainId(_ id: String) {
        chainId = id
        delegate?.chainIdChanged(id)
        
        guard !id.isEmpty else { return }
        store.save(string: id, key: CHAINID_KEY)
    }

    private func updateAccount(_ account: String) {
        self.account = account
        delegate?.accountChanged(account)
        
        guard !account.isEmpty else { return }
        store.save(string: account, key: ACCOUNT_KEY)
    }

    func sendResult(_ result: Any, id: String) {
        getRequest(id: id)?.send(result)
        removeRequest(id: id)
    }

    func sendError(_ error: RequestError, id: String) {
        getRequest(id: id)?.error(error)
        removeRequest(id: id)

        if error.codeType == .unauthorisedRequest {
            clearSession()
        }
    }

    func handleMessage(_ message: [String: Any]) {
        if let id = message["id"] {
            if let identifier: Int64 = id as? Int64 {
                let id: String = String(identifier)
                receiveResponse(message, id: id)
            } else if let identifier: String = id as? String {
                receiveResponse(message, id: identifier)
            }
        } else {
            receiveEvent(message)
        }
    }

    func receiveResponse(_ data: [String: Any], id: String) {
        guard let request = getRequest(id: id) else { return }
        
        track?(.sdkRpcRequestDone, [
            "from": "mobile",
            "method": request.method
        ])

        if let error = data["error"] as? [String: Any] {
            let requestError = RequestError(from: error)
            let method = EthereumMethod(rawValue: request.method)
            if
                method == .ethRequestAccounts,
                requestError.codeType == .userRejectedRequest {
                track?(.connectionRejected, [:])
            }
            sendError(requestError, id: id)

            // metamask_connectSign & metamask_connectwith can have both error & result
            // if connection is approved but rpc request is denied
            let accounts = data["accounts"] as? [String] ?? []

            if let account = accounts.first {
                updateAccount(account)
                sendResult(account, id: id)
            }

            if let chainId = data["chainId"] as? String {
                updateChainId(chainId)
                sendResult(chainId, id: id)
            }

            return
        }

        guard
            let method = EthereumMethod(rawValue: request.method),
            EthereumMethod.isResultMethod(method) else {
            if let result = data["result"] {
                sendResult(result, id: id)
            } else {
                sendResult(data, id: id)
            }
            return
        }

        switch method {
        case .getMetamaskProviderState:
            let result: [String: Any] = data["result"] as? [String: Any] ?? [:]
            let accounts = result["accounts"] as? [String] ?? []

            if let account = accounts.first {
                updateAccount(account)
                sendResult(account, id: id)
            }

            if let chainId = result["chainId"] as? String {
                updateChainId(chainId)
                sendResult(chainId, id: id)
            }
        case .ethRequestAccounts:
            let result: [String] = data["result"] as? [String] ?? []
            if let account = result.first {
                track?(.connectionAuthorised, [:])
                updateAccount(account)
                sendResult(result, id: id)
            } else {
                Logging.error("Ethereum:: Request accounts failure")
            }
        case .ethChainId:
            if let result: String = data["result"] as? String {
                updateChainId(result)
                sendResult(result, id: id)
            }
        case .ethSignTypedDataV4,
                .ethSignTypedDataV3,
                .ethSendTransaction:
            if let result: String = data["result"] as? String {
                sendResult(result, id: id)
            } else {
                Logging.error("Unexpected response \(data)")
            }
        case .metamaskBatch:
            if
                id == Ethereum.BATCH_CONNECTION_ID,
                let result = data["result"] as? [Any],
                result.count == 2,
                let accounts = result.first as? [String],
                let chainId = result[1] as? String {

                if let account = accounts.first {
                    updateAccount(account)
                }
                updateChainId(chainId)
            } else {
                if
                    let accounts = data["accounts"] as? [String],
                    let account = accounts.first {
                    updateAccount(account)
                }
                if let chainId = data["chainId"] as? String {
                    updateChainId(chainId)
                }
                if let result = data["result"] {
                    sendResult(result, id: id)
                }
            }
        default:
            if let chainId = data["chainId"] as? String {
                updateChainId(chainId)
            }

            if
                let accounts = data["accounts"] as? [String],
                let selectedAddress = accounts.first {
                updateAccount(selectedAddress)
            }

            if let result = data["result"] {
                sendResult(result, id: id)
            }
        }
    }

    func receiveEvent(_ event: [String: Any]) {
        if let error = event["error"] as? [String: Any] {
            Logging.error("Ethereum:: receive error: \(error)")
            let requestError = RequestError(from: error)

            if requestError.codeType == .userRejectedRequest {
                track?(.connectionRejected, [:])
            }
            sendError(requestError, id: Ethereum.CONNECTION_ID)
        }

        guard
            let method = event["method"] as? String,
            let ethMethod = EthereumMethod(rawValue: method)
        else {
            if let chainId = event["chainId"] as? String {
                updateChainId(chainId)
            }

            if
                let accounts = event["accounts"] as? [String],
                let selectedAddress = accounts.first {
                updateAccount(selectedAddress)
                sendResult(accounts, id: Ethereum.CONNECTION_ID)
            }
            return
        }

        switch ethMethod {
        case .metaMaskAccountsChanged:
            let accounts: [String] = event["params"] as? [String] ?? []
            if let account = accounts.first {
                updateAccount(account)
            }
        case .metaMaskChainChanged:
            let params: [String: Any] = event["params"] as? [String: Any] ?? [:]

            if let chainId = params["chainId"] as? String {
                updateChainId(chainId)
            }
        default:
            Logging.error("Unhandled case: \(event)")
        }
    }
}
