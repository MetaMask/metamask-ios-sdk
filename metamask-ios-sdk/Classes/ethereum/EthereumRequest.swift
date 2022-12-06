//
//  EthereumRequest.swift
//
//
//  Created by Mpendulo Ndlovu on 2022/11/29.
//

import Foundation


public struct DappMetadata {
    public let name: String
    public let url: String
    
    public init(name: String, url: String) {
        self.name = name
        self.url = url
    }
}

public struct EthereumRequest<T: CodableData>: CodableData {
    public var id: String?
    public let method: EthereumMethod
    public var params: [T]
    
    public init(id: String? = nil, method: EthereumMethod, params: [T] = [""]) {
        self.id = id
        self.method = method
        self.params = params
    }
    
    public func socketRepresentation() -> NetworkData {
        [
            "id": id ?? "",
            "method": method.rawValue,
            "parameters": params.socketRepresentation()
        ]
    }
}

public struct SubmittedRequest {
    public let method: EthereumMethod
}

public enum EthereumMethod: String, CaseIterable, CodableData {
    case ethSign = "eth_sign"
    case ethChainId = "eth_chainId"
    case personalSign = "personal_sign"
    case watchAsset = "wallet_watchAsset"
    case signTypedData = "eth_signTypedData"
    case requestAccounts = "eth_requestAccounts"
    case signTransaction = "eth_signTransaction"
    case sendTransaction = "eth_sendTransaction"
    case signTypedDataV3 = "eth_signTypedData_v3"
    case signTypedDataV4 = "eth_signTypedData_v4"
    case addEthereumChain = "wallet_addEthereumChain"
    case switchEthereumChain = "wallet_switchEthereumChain"
    case metaMaskChainChanged = "metamask_chainChanged"
    case metaMaskAccountsChanged = "metamask_accountsChanged"
    case getMetamaskProviderState = "metamask_getProviderState"
}
