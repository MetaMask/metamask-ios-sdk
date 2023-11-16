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
    private let CONNECTION_ID = UUID().uuidString
    private var submittedRequests: [String: SubmittedRequest] = [:]
    private var cancellables: Set<AnyCancellable> = []
    
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
            let _ = URL(string: urlString)
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
    
    // MARK: Deeplinking
    
    func requiresAuthorisation(method: EthereumMethod) -> Bool {
        switch method {
        case .ethRequestAccounts:
            return account.isEmpty ? true : false
        default:
            return EthereumMethod.requiresDeeplinking(method)
        }
    }
    
    // MARK: Request Sending
    
    func sendRequest<T: CodableData>(_ request: EthereumRequest<T>) {
        commClient.sendMessage(request, encrypt: true)
        let authorise = requiresAuthorisation(method: request.methodType)
        
        if authorise {
            commClient.requestAuthorisation()
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
    func request<T: CodableData>(_ request: EthereumRequest<T>) -> EthereumPublisher? {
        
        if !connected && request.methodType != .metaMaskConnectSign {
            if request.methodType == .ethRequestAccounts {
                commClient.connect()
                connected = true
                return requestAccounts()
            }
            
            let passthroughSubject = PassthroughSubject<Any, RequestError>()
            let publisher: EthereumPublisher = passthroughSubject
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
            
            let error = RequestError.connectError
            passthroughSubject.send(completion: .failure(error))
            return publisher
            
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
    
    func request<T: CodableData>(_ req: EthereumRequest<T>) async -> Result<String, RequestError> {
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
                    continuation.resume(returning: .success("\(result)"))
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
                sendResult(account, id: id)
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
