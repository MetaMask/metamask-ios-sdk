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

public class Ethereum {
    static var sdk: MetaMaskSDK!
    public static var chainId: String?
    public static var connected: Bool = false
    public static var selectedAddress: String?
    public static var dappMetaData: DappMetadata?
    
    private static var onChainIdChanged: ((String?) -> Void)? = { id in
        chainId = id
    }
    
    private static var onAccountsChanged: (([String]) -> Void)? = { accounts in
        selectedAddress = accounts.first
    }
    
    private static var dappMetadata: DappMetadata?
    private static var requests: [String: SubmittedRequest] = [:]
}

// MARK: Session Management
extension Ethereum {
    
    public static func initialise() {
        let request = EthereumRequest(
            id: nil,
            method: .getMetamaskProviderState,
            params: [])
        makeRequest(request)
    }
    
    @discardableResult public static func connect(_ metaData: DappMetadata) -> RequestTask? {
        dappMetadata = metaData
        
        let request = EthereumRequest(
            id: nil,
            method: .requestAccounts,
            params: [])
        return makeRequest(request)
    }
    
    public static func disconnect() {
        connected = false
        chainId = nil
        selectedAddress = nil
    }
}

// MARK: Deeplinking
extension Ethereum {
    public static func shouldOpenMetaMask(method: EthereumMethod) -> Bool {
        if method == .requestAccounts && selectedAddress == nil {
            return true
        } else if method == .requestAccounts {
            return false
        }
        
        return EthereumMethod.allCases.contains(method)
    }
}

// MARK: Request Sending
extension Ethereum {
    public static func sendRequest(_ request: EthereumRequest,
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
    
    static func requestAccounts(task: RequestTask?) {
        connected = true
        initialise()
        
        let method: EthereumMethod = .requestAccounts
        let request = EthereumRequest(
            method: method,
            params: [])
        
        let id = UUID().uuidString
        let submittedRequest = SubmittedRequest(
            method: method,
            task: task)
        
        requests[id] = submittedRequest
        sendRequest(
            request,
            id: id,
            openDeeplink: false)
    }
    
    @discardableResult public static func makeRequest(_ request: EthereumRequest) -> RequestTask?{
        var task: RequestTask?
        
        if request.method == .requestAccounts && connected {
            sdk = MetaMaskSDK()
            sdk.url = dappMetaData?.url
            sdk.name = dappMetaData?.name
            sdk.connect()
            sdk.onClientsReady = requestAccounts
        } else if !connected {
            Logging.error(EthereumError.notConnected)
            return nil
        } else {
            let id = UUID().uuidString.lowercased()
            let submittedRequest = SubmittedRequest(
                method: request.method,
                task: task)
            requests[id] = submittedRequest
            
            sendRequest(
                request,
                id: id,
                openDeeplink: shouldOpenMetaMask(method: request.method))
        }
        
        return task
    }
}

// MARK: Request Receiving
extension Ethereum {
    public static func receiveRequest(id: String, data: [String: Any]) {
        guard let request = requests[id] else { return }
        
        if data["error"] != nil {
            requests[id] = nil
            return
        }
        
        let method = request.method
        
        switch method {
        case .getMetamaskProviderState:
            let result: [String: Any] = data["result"] as? [String: Any] ?? [:]
            let accounts = result["accounts"] as? [String] ?? []
            onAccountsChanged?(accounts)
            
            let chainId = result["chainId"] as? String
            onChainIdChanged?(chainId)
        case .requestAccounts:
            let accounts: [String] = []
//            onAccountsChanged?(result)
        default:
            break
        }
        
        //if requests[id]
        onChainIdChanged?(id)
    }
    
    public static func receiveEvent(_ event: [String: Any]) {
        Logging.log("Received ethereum event: \(event)")
        guard
            let method = event["method"] as? String,
            let ethereumMethod = EthereumMethod(rawValue: method)
        else { return }
        
        switch ethereumMethod {
        case .metaMaskAccountsChanged:
            let accounts: [String] = event["params"] as? [String] ?? []
            onAccountsChanged?(accounts)
        case .metaMaskChainChanged:
            let params: [String: Any] = event["params"] as? [String: Any] ?? [:]
            let chainId = params["chainId"] as? String ?? ""
            onChainIdChanged?(chainId)
        default:
            break
        }
    }
}
