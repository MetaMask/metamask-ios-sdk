//
//  Ethereum.swift
//

import UIKit
import Combine
import Foundation

public typealias EthereumPublisher = AnyPublisher<Any, RequestError>

public class Ethereum: ObservableObject {
    weak var delegate: SDKDelegate?
    private let CONNECTION_ID = UUID().uuidString
    private var submittedRequests: [String: SubmittedRequest] = [:]

    /// The active/selected MetaMask account chain
    @Published public var chainId: String = ""
    /// Indicated whether connected to MetaMask
    @Published public var connected: Bool = false

    /// The active/selected MetaMask account address
    @Published public var selectedAddress: String = ""

    /// In debug mode we track three events: connection request, connected, disconnected, otherwise no tracking
    public var enableDebug: Bool {
        get {
            delegate?.enableDebug ?? true
        } set {
            delegate?.enableDebug = newValue
        }
    }
    
    public var useDeeplinks: Bool {
        get {
            delegate?.useDeeplinks ?? false
        } set {
            delegate?.useDeeplinks = newValue
        }
    }

    /// Set and use a custom network url. Currently fully supported
    public var networkUrl: String {
        get {
            delegate?.networkUrl ?? ""
        } set {
            delegate?.networkUrl = newValue
        }
    }
}

// MARK: Session Management

public extension Ethereum {
    @discardableResult
    private func getMetamaskProviderState() -> EthereumPublisher? {
        let providerRequest = EthereumRequest(
            method: .getMetamaskProviderState
        )

        return request(providerRequest)
    }

    @discardableResult
    /// Connect to MetaMask mobile wallet. This method must be called first and once, to establish a connection before any requests can be made
    /// - Parameter dapp: A struct describing the dapp making the request
    /// - Returns: A Combine publisher that will emit a connection result or error once a response is received
    func connect(_ dapp: Dapp) -> EthereumPublisher? {
        delegate?.dapp = dapp
        delegate?.connect()
        
        return requestAccounts()
    }
    
    func connectAndSign(message: String) -> EthereumPublisher? {
        delegate?.connect()
        
        let connectSignRequest = EthereumRequest(
            method: .metaMaskConnectSign,
            params: [message]
        )
        
        return request(connectSignRequest)
    }

    /// Disconnect dapp
    func disconnect() {
        connected = false
        delegate?.disconnect()
    }
    
    func clearSession() {
        delegate?.clearSession()
    }
    
    func terminateConnection() {
        if connected {
            delegate?.trackEvent(.connectionRejected)
        }
        
        let error = RequestError(from: ["message": "The connection request has been rejected"])
        submittedRequests.forEach { key, value in
            submittedRequests[key]?.error(error)
        }
        submittedRequests.removeAll()
        disconnect()
    }
}

// MARK: Deeplinking

private extension Ethereum {
    func requiresAuthorisation(method: EthereumMethod) -> Bool {
        switch method {
        case .ethRequestAccounts:
            return selectedAddress.isEmpty ? true : false
        default:
            return EthereumMethod.requiresDeeplinking(method)
        }
    }
}

// MARK: Request Sending

extension Ethereum {
    func sendRequest<T: CodableData>(_ request: EthereumRequest<T>,
                                     authorise: Bool,
                                     encrypt: Bool = true) {
        delegate?.sendMessage(request, encrypt: encrypt)
        if authorise {
            delegate?.requestAuthorisation()
        }
    }

    @discardableResult
    func requestAccounts() -> EthereumPublisher? {
        //getMetamaskProviderState()
        
        let requestAccountsRequest = EthereumRequest(
            id: CONNECTION_ID,
            method: .ethRequestAccounts
        )
        
        let submittedRequest = SubmittedRequest(method: requestAccountsRequest.method)
        submittedRequests[CONNECTION_ID] = submittedRequest
        
        let publisher = submittedRequests[CONNECTION_ID]?.publisher

        delegate?.addRequest { [weak self] in
            self?.sendRequest(
                requestAccountsRequest,
                authorise: false,
                encrypt: false
            )
        }
        
        return publisher
    }

    @discardableResult
    /// Performs and Ethereum remote procedural call (RPC)
    /// - Parameter request: The RPC request. It's `parameters` need to conform to `CodableData`
    /// - Returns: A Combine publisher that will emit a result or error once a response is received
    public func request<T: CodableData>(_ request: EthereumRequest<T>) -> EthereumPublisher? {

        if request.methodType == .ethRequestAccounts {

            let submittedRequest = SubmittedRequest(method: request.method)
            submittedRequests[CONNECTION_ID] = submittedRequest
            let publisher = submittedRequests[CONNECTION_ID]?.publisher

            delegate?.addRequest { [weak self] in
                self?.requestAccounts()
            }
            return publisher
        } else {
            let id = request.id
            let submittedRequest = SubmittedRequest(method: request.method)
            submittedRequests[id] = submittedRequest
            let publisher = submittedRequests[id]?.publisher
            Logging.log("Mpendulo:: Sending request for \(request.method), id: \(id)")
            
            if !connected {
                Logging.log("Mpendulo:: Connectingng delegate")
                delegate?.connect()
                connected = true
                delegate?.addRequest {
                    self.makeRequest(request)
                }
            } else {
                Logging.log("Mpendulo:: Delegate already connected")
                makeRequest(request)
            }
            return publisher
        }
    }
    
    private func makeRequest<T: CodableData>(_ request: EthereumRequest<T>) {
        if let method = EthereumMethod(rawValue: request.method) {
            sendRequest(
                request,
                authorise: connected ? requiresAuthorisation(method: method) : true
            )
        } else {
            sendRequest(
                request,
                authorise: connected ? false : true
            )
        }
    }
}

// MARK: Request Receiving

extension Ethereum {
    private func updateChainId(_ id: String) {
        chainId = id
    }

    private func updateAccount(_ account: String) {
        selectedAddress = account
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
                delegate?.trackEvent(.connectionRejected)
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
                Logging.log("Mpendulo:: Got account: \(account)")
                updateAccount(account)
                sendResult(account, id: id)
            }

            if let chainId = result["chainId"] as? String {
                Logging.log("Mpendulo:: Got chainId: \(chainId)")
                updateChainId(chainId)
                sendResult(chainId, id: id)
            }
        case .ethRequestAccounts:
            let result: [String] = data["result"] as? [String] ?? []
            if let account = result.first {
                delegate?.trackEvent(.connectionAuthorised)
                Logging.log("Mpendulo:: Got ethRequestAccounts: \(account)")
                updateAccount(account)
                sendResult(account, id: id)
            } else {
                Logging.error("Request accounts failure")
            }
        case .ethChainId:
            if let result: String = data["result"] as? String {
                Logging.log("Mpendulo:: Got ethChainId: \(result)")
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
        case .metaMaskConnectSign:
            Logging.log("Mpendulo:: Got metaMaskConnectSign: \(data)")
        default:
            if let result = data["result"] {
                Logging.log("Mpendulo:: Got default: \(data)")
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
