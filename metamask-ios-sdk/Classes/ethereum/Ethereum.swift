//
//  Ethereum.swift
//
//
//  Created by Mpendulo Ndlovu on 2022/11/29.
//
import Foundation
import Combine

public enum EthereumError: Error {
    case notConnected
    case custom(String)
    
    var message: String {
        switch self {
        case .notConnected: return "Wait until MetaMask is connected"
        case .custom(let error): return error
        }
    }
}

public class Ethereum: ObservableObject {
    public static let shared = Ethereum()
    
    @Published public var chainId: String?
    @Published public var connected: Bool = false
    @Published public var selectedAddress: String = ""
    
    private var sdk = MMSDK()
    private var dappMetadata: DappMetadata!
    private var submittedRequests: [String: SubmittedRequest] = [:]
}

// MARK: Session Management
extension Ethereum {
    @discardableResult
    private func initialise() -> AnyPublisher<String, Never>? {
        let providerRequest = EthereumRequest(
            id: nil,
            method: .getMetamaskProviderState)
        
        return request(providerRequest)
    }
    
    @discardableResult
    public func connect(_ metaData: DappMetadata) -> AnyPublisher<String, Never>? {
        dappMetadata = metaData
        
        let accountsRequest = EthereumRequest(
            id: nil,
            method: .requestAccounts)
        Logging.log("mmsdk| Connecting dapp \(dappMetadata.name) to ethereum")
        
        return request(accountsRequest)
    }
    
    public func disconnect() {
        connected = false
        chainId = nil
        selectedAddress = ""
    }
}

// MARK: Deeplinking
extension Ethereum {
    func shouldOpenMetaMask(method: EthereumMethod) -> Bool {
        switch method {
        case .requestAccounts:
            return selectedAddress.isEmpty ? true : false
        default:
            return EthereumMethod.allCases.contains(method)
        }
    }
}

// MARK: Request Sending
extension Ethereum {
    func sendRequest<T: CodableData>(_ request: EthereumRequest<T>,
                                            id: String,
                                            openDeeplink: Bool) {
        Logging.log("mmsdk| Sending request \(request.method) \(request.params)")
        
        var request = request
        request.id = id
        sdk.sendMessage(request, encrypt: true)
            
        if
            openDeeplink,
            let url = URL(string: "https://metamask.app.link") {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func requestAccounts(_ publisher: inout AnyPublisher<String, Never>?)  {
        Logging.log("mmsdk| Requesting accounts")
        connected = true
        initialise()
        
        let method: EthereumMethod = .requestAccounts
        let request = EthereumRequest<String>(
            method: method,
            params: [])
        
        let id = UUID().uuidString.lowercased()
        let submittedRequest = SubmittedRequest(method: method)
        
        submittedRequests[id] = submittedRequest
        publisher = submittedRequests[id]?.publisher
        
        sendRequest(
            request,
            id: id,
            openDeeplink: false)
    }
    
    @discardableResult
    public func request<T: CodableData>(_ request: EthereumRequest<T>) -> AnyPublisher<String, Never>? {
        var publisher: AnyPublisher<String, Never>?
        
        if request.method == .requestAccounts && !connected {
            sdk.dappUrl = dappMetadata.url
            sdk.dappName = dappMetadata.name
            sdk.connect()
            sdk.onClientsReady = { [weak self] in
                self?.requestAccounts(&publisher)
            }
        } else if !connected {
            Logging.error(EthereumError.notConnected)
        } else {
            let id = UUID().uuidString.lowercased()
            let submittedRequest = SubmittedRequest(method: request.method)
            submittedRequests[id] = submittedRequest
            publisher = submittedRequests[id]?.publisher
            
            sendRequest(
                request,
                id: id,
                openDeeplink: shouldOpenMetaMask(method: request.method))
        }
        
        return publisher
    }
}

// MARK: Request Receiving
extension Ethereum {
    private func updateChainId(_ id: String?) {
        chainId = id
    }
    
    private func updateAccount(_ account: String) {
        selectedAddress = account
    }
    
    func receiveResponse(id: String, data: [String: Any]) {
        Logging.log("mmsdk| Received ethereum response: \(data)")
        
        guard let request = submittedRequests[id] else { return }
        
        if data["error"] != nil {
            return
        }
        
        let method = request.method
        
        switch method {
        case .getMetamaskProviderState:
            let result: [String: Any] = data["result"] as? [String: Any] ?? [:]
            let accounts = result["accounts"] as? [String] ?? []
            
            if let account = accounts.first {
                updateAccount(account)
                _ = submittedRequests[id]?.send(account)
            }
            
            if let chainId = result["chainId"] as? String {
                updateChainId(chainId)
                _ = submittedRequests[id]?.send(chainId)
            }
        case .requestAccounts:
            let result: [String] = data["result"] as? [String] ?? []
            if let account = result.first {
                Logging.log("mmsdk| Request accounts result: \(account)")
                updateAccount(account)
                submittedRequests[id]?.send(account)
            } else {
                Logging.error("mmsdk| Sign signature v4 failure: \(data)")
            }
        case .ethChainId:
            if let result: String = data["result"] as? String {
                updateChainId(result)
                Logging.log("mmsdk| Eth chain_id changed: \(result)")
                submittedRequests[id]?.send(result)
            }
        case .signTypedDataV4:
            if let result: String = data["result"] as? String {
                Logging.log("mmsdk| Sign signature v4 result: \(result)")
                submittedRequests[id]?.send(result)
            } else {
                Logging.error("mmsdk| Sign signature v4 failure: \(data)")
            }
        case .sendTransaction:
            if let result: String = data["result"] as? String {
                Logging.log("mmsdk| Send transaction result: \(result)")
                submittedRequests[id]?.send(result)
            } else {
                Logging.error("mmsdk| Send transaction failure: \(data)")
            }
        default:
            Logging.log("mmsdk| Unhandled result: \(data)")
            break
        }
    }
    
    func receiveEvent(_ event: [String: Any]) {
        Logging.log("mmsdk| Received ethereum event: \(event)")
        
        guard
            let method = event["method"] as? String,
            let ethereumMethod = EthereumMethod(rawValue: method)
        else { return }
        
        switch ethereumMethod {
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
            break
        }
    }
}
