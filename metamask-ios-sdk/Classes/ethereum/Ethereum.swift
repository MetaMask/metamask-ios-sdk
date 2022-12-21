//
//  Ethereum.swift
//

import Foundation
import Combine

public enum EthereumError: Error {
    case notConnected
    case requestError(String)
    
    public var localizedDescription: String {
        switch self {
        case .notConnected: return "Wait until MetaMask is connected"
        case .requestError(let error): return error
        }
    }
}

public typealias EthereumPublisher = AnyPublisher<String, EthereumError>
public class Ethereum: ObservableObject {
    public static let shared = Ethereum()
    
    @Published public var chainId: String?
    @Published public var connected: Bool = false
    @Published public var selectedAddress: String = ""
    
    private var connectionId = "connection-id"
    private var sdk = MMSDK()
    private var dappMetadata: DappMetadata!
    private var submittedRequests: [String: SubmittedRequest] = [:]
}

// MARK: Session Management
extension Ethereum {
    @discardableResult
    private func initialise() -> EthereumPublisher? {
        let providerRequest = EthereumRequest(
            id: nil,
            method: .getMetamaskProviderState)
        
        return request(providerRequest)
    }
    
    @discardableResult
    public func connect(_ metaData: DappMetadata) -> EthereumPublisher? {
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
    
    func requestAccounts()  {
        connected = true
        initialise()
        
        sendRequest(
            EthereumRequest(method: .requestAccounts),
            id: connectionId,
            openDeeplink: false)
    }
    
    @discardableResult
    public func request<T: CodableData>(_ request: EthereumRequest<T>) -> EthereumPublisher? {
        var publisher: EthereumPublisher?
        
        if request.method == .requestAccounts && !connected {
            sdk.dappUrl = dappMetadata.url
            sdk.dappName = dappMetadata.name
            sdk.connect()

            let submittedRequest = SubmittedRequest(method: .requestAccounts)
            submittedRequests[connectionId] = submittedRequest
            publisher = submittedRequests[connectionId]?.publisher
            sdk.onClientsReady = requestAccounts
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
        guard let request = submittedRequests[id] else { return }
        
        if let error = data["error"] as? [String: Any] {
            let code = error["code"] as? Int ?? -1
            
            if let message = error["message"] as? String {
                submittedRequests[id]?.error(EthereumError.requestError(message))
            } else if code == 4001 {
                submittedRequests[id]?.error(EthereumError.requestError("User rejected the request."))
            } else {
                submittedRequests[id]?.error(EthereumError.requestError("Request failed with error code \(code)"))
            }
            return
        }
        
        let method = request.method
        
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
                Logging.error("mmsdk| Request accounts failure")
            }
        case .ethChainId:
            if let result: String = data["result"] as? String {
                updateChainId(result)
                submittedRequests[id]?.send(result)
            }
        case .signTypedDataV4:
            if let result: String = data["result"] as? String {
                submittedRequests[id]?.send(result)
            } else {
                Logging.error("mmsdk| Sign signature v4 failure")
            }
        case .sendTransaction:
            if let result: String = data["result"] as? String {
                submittedRequests[id]?.send(result)
            } else {
                Logging.error("mmsdk| Send transaction failure")
            }
        default:
            Logging.log("mmsdk| Unhandled result")
            break
        }
    }
    
    func receiveEvent(_ event: [String: Any]) {
        
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
