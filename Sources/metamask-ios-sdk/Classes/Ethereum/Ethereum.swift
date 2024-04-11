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
    private static let BATCH_CONNECTION_ID = TimestampGenerator.timestamp()
    private var submittedRequests: [String: SubmittedRequest] = [:]
    private var cancellables: Set<AnyCancellable> = []
    
    var sdkOptions: SDKOptions?
    
    weak var delegate: EthereumEventsDelegate?

    private var connected: Bool = false
    
    /// The active/selected MetaMask account chain
    private var chainId: String = ""
    
    /// The active/selected MetaMask account address
    private var account: String = ""
    
    var commClient: CommClient
    private var track: ((Event, [String: Any]) -> Void)?
    
    private var appMetaDataValidationError: EthereumPublisher? {
        guard
            let urlString = commClient.appMetadata?.url,
            let url = URL(string: urlString),
            url.host != nil,
            url.scheme != nil
        else {
            return RequestError.failWithError(.invalidUrlError)
        }
        
        if commClient.appMetadata?.name.isEmpty ?? true {
            return RequestError.failWithError(.invalidTitleError)
        }
        return nil
    }
    
    private init(commClient: CommClient, track: @escaping ((Event, [String: Any]) -> Void)) {
        self.track = track
        self.commClient = commClient
        self.commClient.trackEvent = trackEvent
        //self.commClient.terminateConnection()
        self.commClient.handleResponse = handleMessage
        //self.commClient.tearDownConnection = disconnect
        //self.commClient.receiveResponse = receiveResponse
        //self.commClient.onClientsTerminated = terminateConnection
    }
    
    public static func shared(commClient: CommClient,
                              trackEvent: @escaping ((Event, [String: Any]) -> Void)) -> Ethereum {
        guard let ethereum = EthereumWrapper.shared.ethereum else {
            let ethereum = Ethereum(commClient: commClient, track: trackEvent)
            EthereumWrapper.shared.ethereum = ethereum
            return ethereum
        }
        return ethereum
    }
    
    private func trackEvent(event: Event, parameters: [String: Any]) {
        track?(event, parameters)
    }
    
    func updateMetadata(_ metadata: AppMetadata) {
        commClient.appMetadata = metadata
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
        submittedRequests[Ethereum.CONNECTION_ID] = submittedRequest
        let publisher = submittedRequests[Ethereum.CONNECTION_ID]?.publisher

        return publisher
    }
    
    @discardableResult
    func connect() async -> Result<String, RequestError> {
        return await withCheckedContinuation { continuation in
            connect()?
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: .success(""))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }, receiveValue: { result in
                    continuation.resume(returning: .success("\(result)"))
                }).store(in: &cancellables)
        }
    }
    
    func connectAndSign(message: String) -> EthereumPublisher? {
        if commClient is SocketClient {
            commClient.connect(with: nil)
            
            let connectSignRequest = EthereumRequest(
                method: .metaMaskConnectSign,
                params: [message]
            )
            connected = true
            return request(connectSignRequest)
        }
        
        let connectSignRequest = EthereumRequest(
            method: .metaMaskConnectSign,
            params: [message]
        )
        
        let submittedRequest = SubmittedRequest(method: connectSignRequest.method)
        submittedRequests[connectSignRequest.id] = submittedRequest
        let publisher = submittedRequests[connectSignRequest.id]?.publisher
        
        let requestJson = connectSignRequest.toJsonString() ?? ""
        
        commClient.connect(with: requestJson)
        connected = true
        
        return publisher
    }
    
    func connectAndSign(message: String) async -> Result<String, RequestError> {
        return await withCheckedContinuation { continuation in
            connectAndSign(message: message)?
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: .success(""))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }, receiveValue: { result in
                    continuation.resume(returning: .success("\(result)"))
                }).store(in: &cancellables)
        }
    }
    
    func connectWith<T: CodableData>(_ req: EthereumRequest<T>) async -> Result<String, RequestError> {
        let params: [EthereumRequest] = [req]
        let connectWithRequest = EthereumRequest(
            method: EthereumMethod.metamaskConnectWith.rawValue,
            params: params
        )
        
        let submittedRequest = SubmittedRequest(method: connectWithRequest.method)
        submittedRequests[connectWithRequest.id] = submittedRequest
        let publisher = submittedRequests[connectWithRequest.id]?.publisher
        
        let requestJson = connectWithRequest.toJsonString() ?? ""
        
        commClient.connect(with: requestJson)
        
        connected = true
        
        return await withCheckedContinuation { continuation in
            publisher?
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: .success(""))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }, receiveValue: { result in
                    continuation.resume(returning: .success("\(result)"))
                }).store(in: &cancellables)
        }
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
    
    func sendTransaction(from: String, to: String, amount: String) async -> Result<String, RequestError> {
        await ethereumRequest(method: .ethSendTransaction, params: [
            [
                "from": from,
                "to": to,
                "amount": amount
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
        updateChainId("")
        updateAccount("")
        connected = false
        commClient.disconnect()
    }
    
    func clearSession() {
        updateAccount("")
        updateChainId("")
        connected = false
        commClient.clearSession()
    }
    
    func terminateConnection() {
        if connected {
            track?(.connectionRejected, [:])
        }
        
        let error = RequestError(from: ["message": "The connection request has been rejected"])
        submittedRequests.forEach { key, value in
            submittedRequests[key]?.error(error)
        }
        submittedRequests.removeAll()
        disconnect()
    }
    
    // MARK: Request Sending
    
    func sendRequest(_ request: any RPCRequest) {
        if
            EthereumMethod.isReadOnly(request.methodType),
            let sdkOptions = sdkOptions,
            !sdkOptions.infuraAPIKey.isEmpty {
            let infuraProvider = InfuraProvider(infuraAPIKey: sdkOptions.infuraAPIKey)
            Task {
                if let result = await infuraProvider.sendRequest(
                    request,
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
            if commClient is SocketClient {
                (commClient as? SocketClient)?.sendMessage(request, encrypt: true)
                
                let authorise = EthereumMethod.requiresAuthorisation(request.methodType)
                let skipAuthorisation = request.methodType == .ethRequestAccounts && !account.isEmpty
                
                if authorise && !skipAuthorisation {
                    (commClient as? SocketClient)?.requestAuthorisation()
                }
            } else {
                guard let requestJson = request.toJsonString() else {
                    Logging.error("Ethereum:: could not convert request to JSON: \(request)")
                    return
                } 
                
                commClient.sendMessage(requestJson, encrypt: true)
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
        submittedRequests[requestAccountsRequest.id] = submittedRequest
        let publisher = submittedRequests[requestAccountsRequest.id]?.publisher
        
        commClient.addRequest { [weak self] in
            self?.sendRequest(requestAccountsRequest)
        }
        
        return publisher
    }
    
    private func createChainIdRequest() -> EthereumRequest<String> {
        let chainIdRequest = EthereumRequest(
            method: .ethChainId
        )
        
        let submittedRequest = SubmittedRequest(method: chainIdRequest.method)
        submittedRequests[chainIdRequest.id] = submittedRequest
        
        return chainIdRequest
    }
    
    @discardableResult
    private func requestChainId() -> EthereumPublisher? {
        let chainIdRequest = EthereumRequest(
            method: .ethChainId
        )
        
        let submittedRequest = SubmittedRequest(method: chainIdRequest.method)
        submittedRequests[chainIdRequest.id] = submittedRequest
        let publisher = submittedRequests[chainIdRequest.id]?.publisher
        
        sendRequest(chainIdRequest)
        
        return publisher
    }
    
    @discardableResult
    /// Performs and Ethereum remote procedural call (RPC)
    /// - Parameter request: The RPC request. It's `parameters` need to conform to `CodableData`
    /// - Returns: A Combine publisher that will emit a result or error once a response is received
    func request(_ request: any RPCRequest) -> EthereumPublisher? {
        if !connected && !EthereumMethod.isConnectMethod(request.methodType) {
            if request.methodType == .ethRequestAccounts {
                commClient.connect(with: nil)
                connected = true
                return requestAccounts()
            }
            return RequestError.failWithError(.connectError)
        } else {
            let id = request.id
            let submittedRequest = SubmittedRequest(method: request.method)
            submittedRequests[id] = submittedRequest
            let publisher = submittedRequests[id]?.publisher
            
            if connected {
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
    
    func request(_ req: any RPCRequest) async -> Result<String, RequestError> {
        return await withCheckedContinuation { continuation in
            request(req)?
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: .success(""))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }, receiveValue: { result in
                    continuation.resume(returning: .success(result as? String ?? ""))
                }).store(in: &cancellables)
        }
    }
    
    func request(_ req: any RPCRequest) async -> Result<[String], RequestError> {
        return await withCheckedContinuation { continuation in
            request(req)?
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: .success([]))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }, receiveValue: { result in
                    continuation.resume(returning: .success(result as? [String] ?? []))
                }).store(in: &cancellables)
        }
    }
    
    func batchRequest<T: CodableData>(_ params: [EthereumRequest<T>]) async -> Result<[String], RequestError> {
        let batchRequest = EthereumRequest(
            method: EthereumMethod.metamaskBatch.rawValue,
            params: params)

        return await withCheckedContinuation { continuation in
            request(batchRequest)?
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: .success([]))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }, receiveValue: { result in
                    continuation.resume(returning: .success(result as? [String] ?? []))
                }).store(in: &cancellables)
        }
    }
    
    // MARK: Request Receiving
    private func updateChainId(_ id: String) {
        chainId = id
        delegate?.chainIdChanged(id)
    }
    
    private func updateAccount(_ account: String) {
        self.account = account
        delegate?.accountChanged(account)
    }
    
    func sendResult(_ result: Any, id: String) {
        submittedRequests[id]?.send(result)
        submittedRequests.removeValue(forKey: id)
    }
    
    func sendError(_ error: RequestError, id: String) {
        submittedRequests[id]?.error(error)
        submittedRequests.removeValue(forKey: id)
        
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
        guard let request = submittedRequests[id] else { return }
        
        if let error = data["error"] as? [String: Any] {
            let requestError = RequestError(from: error)
            let method = EthereumMethod(rawValue: request.method)
            if
                method == .ethRequestAccounts,
                requestError.codeType == .userRejectedRequest
            {
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
        
        track?(.sdkRpcRequestDone, [
            "from": "mobile",
            "method": request.method
        ])
        
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
            } else if let result = data["result"] {
                sendResult(result, id: id)
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
            
            if requestError.codeType == .userRejectedRequest
            {
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
