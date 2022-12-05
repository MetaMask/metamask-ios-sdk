//
//  Ethereum.swift
//
//
//  Created by Mpendulo Ndlovu on 2022/11/29.
//
import Foundation

public enum EthereumError: String, Error {
    case notConnected = "Wait until MetaMask is connected"
}

public class Ethereum: ObservableObject {
    public static let shared = Ethereum()
    
    @Published public var chainId: String?
    @Published public var connected: Bool = false
    @Published public var selectedAddress: String?
    
    private var transport: Transport!
    private var dappMetadata: DappMetadata!
    private var submittedRequests: [String: SubmittedRequest] = [:]
}

// MARK: Session Management
extension Ethereum {
    
    public func initialise() {
        let providerRequest = EthereumRequest(
            id: nil,
            method: .getMetamaskProviderState,
            params: [])
        Logging.log("Initialising ethereum, request: \(providerRequest)")
        request(providerRequest)
    }
    
    public func connect(_ metaData: DappMetadata) {
        dappMetadata = metaData
        
        let accountsRequest = EthereumRequest(
            id: nil,
            method: .requestAccounts,
            params: [])
        Logging.log("Connecting ethereum with request: \(accountsRequest)")
        request(accountsRequest)
    }
    
    public func disconnect() {
        connected = false
        chainId = nil
        selectedAddress = nil
    }
}

// MARK: Deeplinking
extension Ethereum {
    public func shouldOpenMetaMask(method: EthereumMethod) -> Bool {
        switch method {
        case .requestAccounts:
            return selectedAddress == nil ? true : false
        default:
            return EthereumMethod.allCases.contains(method)
        }
    }
}

// MARK: Request Sending
extension Ethereum {
    public func sendRequest(_ request: EthereumRequest,
                                   id: String,
                                   openDeeplink: Bool) {
        var request = request
        request.id = id
        transport.sendMessage(request, encrypt: true)
            
        if
            openDeeplink,
            let url = URL(string: "https://metamask.app.link") {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func requestAccounts() {
        Logging.log("Requesting accounts...")
        connected = true
        initialise()
        
        let method: EthereumMethod = .requestAccounts
        let request = EthereumRequest(
            method: method,
            params: [])
        
        let id = UUID().uuidString.lowercased()
        let submittedRequest = SubmittedRequest(method: method)
        
        submittedRequests[id] = submittedRequest
        Logging.log("Submitting ethereum request: \(request)")
        sendRequest(
            request,
            id: id,
            openDeeplink: false)
    }
    
    public func request(_ request: EthereumRequest) {
        if request.method == .requestAccounts && !connected {
            transport = Transport()
            transport.url = dappMetadata.url
            transport.name = dappMetadata.name
            transport.connect()
            transport.onClientsReady = requestAccounts
        } else if !connected {
            Logging.error(EthereumError.notConnected)
        } else {
            let id = UUID().uuidString.lowercased()
            let submittedRequest = SubmittedRequest(method: request.method)
            submittedRequests[id] = submittedRequest
            
            sendRequest(
                request,
                id: id,
                openDeeplink: shouldOpenMetaMask(method: request.method))
        }
    }
}

// MARK: Request Receiving
extension Ethereum {
    func updateChainId(_ id: String?) {
        chainId = id
    }
    
    func updateAccount(_ account: String) {
        selectedAddress = account
    }
    
    public func receiveRequest(id: String, data: [String: Any]) {
        guard let request = submittedRequests[id] else { return }
        
        if data["error"] != nil {
            submittedRequests[id] = nil
            return
        }
        
        let method = request.method
        
        switch method {
        case .getMetamaskProviderState:
            let result: [String: Any] = data["result"] as? [String: Any] ?? [:]
            let accounts = result["accounts"] as? [String] ?? []
            
            if let account = accounts.first {
                updateAccount(account)
            }
            
            if let chainId = result["chainId"] as? String {
                updateChainId(chainId)
            }
        case .requestAccounts:
            let result: [String] = data["result"] as? [String] ?? []
            if let account = result.first {
                updateAccount(account)
            }
        case .ethChainId:
            if let result: String = data["result"] as? String {
                updateChainId(result)
            }
        default:
            break
        }
    }
    
    public func receiveEvent(_ event: [String: Any]) {
        Logging.log("Received ethereum event: \(event)")
        
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
