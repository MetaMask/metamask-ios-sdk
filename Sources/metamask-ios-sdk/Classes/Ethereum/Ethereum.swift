//
//  Ethereum.swift
//

import UIKit
import Combine
import Foundation

public typealias EthereumPublisher = AnyPublisher<Any, RequestError>

public class Ethereum: ObservableObject {
    weak var delegate: SDKDelegate?
    private let CONNECTION_ID = "connection-id"
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
    private func initialise() -> EthereumPublisher? {
        let providerRequest = EthereumRequest(
            id: nil,
            method: "metamask_getProviderState"
        )

        return request(providerRequest)
    }

    @discardableResult
    /// Connect to MetaMask mobile wallet. This method must be called first and once, to establish a connection before any requests can be made
    /// - Parameter dapp: A struct describing the dapp making the request
    /// - Returns: A Combine publisher that will emit a connection result or error once a response is received
    func connect(_ dapp: Dapp) -> EthereumPublisher? {
        delegate?.dapp = dapp

        let accountsRequest = EthereumRequest(
            id: nil,
            method: "eth_requestAccounts"
        )

        return request(accountsRequest)
    }

    /// Disconnect dapp
    func disconnect() {
        connected = false
        chainId = ""
        selectedAddress = ""
        delegate?.disconnect()
    }
}

// MARK: Deeplinking

private extension Ethereum {
    func shouldOpenMetaMask(method: DeeplinkMethod) -> Bool {
        switch method {
        case .requestAccounts:
            return selectedAddress.isEmpty ? true : false
        default:
            return DeeplinkMethod.allCases.contains(method)
        }
    }
}

// MARK: Request Sending

extension Ethereum {
    func sendRequest<T: CodableData>(_ request: EthereumRequest<T>,
                                     id: String,
                                     openDeeplink: Bool) {
        var request = request
        request.id = id
        delegate?.sendMessage(request, encrypt: true)

        if
            openDeeplink,
            let url = URL(string: "https://metamask.app.link") {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }

    func requestAccounts() {
        connected = true
        initialise()

        sendRequest(
            EthereumRequest(method: "eth_requestAccounts"),
            id: CONNECTION_ID,
            openDeeplink: false
        )
    }

    @discardableResult
    /// Performs and Ethereum remote procedural call (RPC)
    /// - Parameter request: The RPC request. It's `parameters` need to conform to `CodableData`
    /// - Returns: A Combine publisher that will emit a result or error once a response is received
    public func request<T: CodableData>(_ request: EthereumRequest<T>) -> EthereumPublisher? {
        var publisher: EthereumPublisher?

        if request.method == "eth_requestAccounts" && !connected {
            delegate?.connect()

            let submittedRequest = SubmittedRequest(method: "eth_requestAccounts")
            submittedRequests[CONNECTION_ID] = submittedRequest
            publisher = submittedRequests[CONNECTION_ID]?.publisher

            delegate?.onClientsReady = requestAccounts
        } else if !connected {
            Logging.error("Attempted to perform request while not connected")
        } else {
            let id = UUID().uuidString
            let submittedRequest = SubmittedRequest(method: request.method)
            submittedRequests[id] = submittedRequest
            publisher = submittedRequests[id]?.publisher

            if let deeplinkMethod = DeeplinkMethod(rawValue: request.method) {
                sendRequest(
                    request,
                    id: id,
                    openDeeplink: shouldOpenMetaMask(method: deeplinkMethod)
                )
            } else {
                sendRequest(
                    request,
                    id: id,
                    openDeeplink: false
                )
            }
        }

        return publisher
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

    func receiveResponse(id: String, data: [String: Any]) {
        guard let request = submittedRequests[id] else { return }

        if let error = data["error"] as? [String: Any] {
            let RequestError = RequestError(from: error)
            submittedRequests[id]?.error(RequestError)
            return
        }

        guard let method = ResponseMethod(rawValue: request.method) else {
            if let result = data["result"] {
                submittedRequests[id]?.send(result)
            } else {
                submittedRequests[id]?.send(data)
            }
            return
        }

        switch method {
        case .getMetamaskProviderState:
            let result: [String: Any] = data["result"] as? [String: Any] ?? [:]
            let accounts = result["accounts"] as? [String] ?? []

            if let account = accounts.first {
                updateAccount(account)
                submittedRequests[id]?.send(account)
            }

            if let chainId = result["chainId"] as? String {
                updateChainId(chainId)
                submittedRequests[id]?.send(chainId)
            }
        case .requestAccounts:
            let result: [String] = data["result"] as? [String] ?? []
            if let account = result.first {
                updateAccount(account)
                submittedRequests[id]?.send(account)
            } else {
                Logging.error("Request accounts failure")
            }
        case .ethChainId:
            if let result: String = data["result"] as? String {
                updateChainId(result)
                submittedRequests[id]?.send(result)
            }
        case .signTypedDataV4,
             .signTypedDataV3,
             .sendTransaction:
            if let result: String = data["result"] as? String {
                submittedRequests[id]?.send(result)
            } else {
                Logging.error("Unexpected response \(data)")
            }
        default:
            if let result = data["result"] {
                submittedRequests[id]?.send(result)
            } else {
                Logging.error("Unknown response: \(data)")
            }
        }
    }

    func receiveEvent(_ event: [String: Any]) {
        guard
            let method = event["method"] as? String,
            let stateEvent = StateEvent(rawValue: method)
        else {
            Logging.error("Unhandled event: \(event)")
            return
        }

        switch stateEvent {
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
        }
    }
}
