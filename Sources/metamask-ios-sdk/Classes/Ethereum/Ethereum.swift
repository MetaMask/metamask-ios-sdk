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

class Ethereum {
    private let CONNECTION_ID = TimestampGenerator.timestamp()
    private var submittedRequests: [String: SubmittedRequest] = [:]
    private var cancellables: Set<AnyCancellable> = []
    
    var sdkOptions: SDKOptions?
    
    weak var delegate: EthereumEventsDelegate?

    private var connected: Bool = false
    
    /// The active/selected MetaMask account chain
    private var chainId: String = ""
    
    /// The active/selected MetaMask account address
    private var account: String = ""
    
    let commClient: CommunicationClient
    private var trackEvent: ((Event) -> Void)?
    
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
    
    init(commClient: CommunicationClient, trackEvent: @escaping ((Event) -> Void)) {
        self.trackEvent = trackEvent
        self.commClient = commClient
        self.commClient.receiveEvent = receiveEvent
        self.commClient.tearDownConnection = disconnect
        self.commClient.receiveResponse = receiveResponse
        self.commClient.onClientsTerminated = terminateConnection
    }
    
    func updateMetadata(_ metadata: AppMetadata) {
        commClient.appMetadata = metadata
    }
    
    // MARK: Session Management
    
    @discardableResult
    /// Connect to MetaMask mobile wallet. This method must be called first and once, to establish a connection before any requests can be made
    /// - Returns: A Combine publisher that will emit a connection result or error once a response is received
    func connect() -> EthereumPublisher? {
        if let dappValidationError = appMetaDataValidationError {
            return dappValidationError
        }
        
        commClient.connect()
        connected = true
        
        return requestAccounts()
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
        if let dappValidationError = appMetaDataValidationError {
            return dappValidationError
        }
        
        commClient.connect()
        
        let connectSignRequest = EthereumRequest(
            method: .metaMaskConnectSign,
            params: [message]
        )
        
        return request(connectSignRequest)
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
        return await request(connectWithRequest)
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
            trackEvent?(.connectionRejected)
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
            commClient.sendMessage(request, encrypt: true)
            let authorise = EthereumMethod.requiresAuthorisation(request.methodType)
            let skipAuthorisation = request.methodType == .ethRequestAccounts && !account.isEmpty
            
            if authorise && !skipAuthorisation {
                commClient.requestAuthorisation()
            }
        }
    }
    
    @discardableResult
    private func requestAccounts() -> EthereumPublisher? {
        let requestAccountsRequest = EthereumRequest(
            id: CONNECTION_ID,
            method: .ethRequestAccounts
        )
        
        let submittedRequest = SubmittedRequest(method: requestAccountsRequest.method)
        submittedRequests[CONNECTION_ID] = submittedRequest
        let publisher = submittedRequests[CONNECTION_ID]?.publisher
        
        commClient.addRequest { [weak self] in
            self?.sendRequest(requestAccountsRequest)
        }
        
        return publisher
    }
    
    @discardableResult
    /// Performs and Ethereum remote procedural call (RPC)
    /// - Parameter request: The RPC request. It's `parameters` need to conform to `CodableData`
    /// - Returns: A Combine publisher that will emit a result or error once a response is received
    func request(_ request: any RPCRequest) -> EthereumPublisher? {
        if !connected && !EthereumMethod.isConnectMethod(request.methodType) {
            if request.methodType == .ethRequestAccounts {
                commClient.connect()
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
                commClient.connect()
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
    }
    
    func receiveResponse(id: String, data: [String: Any]) {
        guard let request = submittedRequests[id] else { return }
        
        if let error = data["error"] as? [String: Any] {
            let requestError = RequestError(from: error)
            let method = EthereumMethod(rawValue: request.method)
            if
                method == .ethRequestAccounts,
                requestError.codeType == .userRejectedRequest
            {
                trackEvent?(.connectionRejected)
            }
            sendError(requestError, id: id)
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
                trackEvent?(.connectionAuthorised)
                updateAccount(account)
                sendResult(result, id: id)
            } else {
                Logging.error("Request accounts failure")
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
        default:
            if let result = data["result"] {
                sendResult(result, id: id)
            } else {
                Logging.error("Unknown response: \(data)")
            }
        }
    }
    
    func receiveEvent(_ event: [String: Any]) {
        guard
            let method = event["method"] as? String,
            let ethMethod = EthereumMethod(rawValue: method)
        else {
            Logging.error("Unhandled event: \(event)")
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

extension Ethereum {
    static let live = Dependencies.shared.ethereum
}
