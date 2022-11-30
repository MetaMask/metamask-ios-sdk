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
}

public struct EthereumRequest: CodableData {
    public var id: String?
    public let method: EthereumMethod
    public var params: [String]
    
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
    public var task: RequestTask?
}

public enum EthereumMethod: String, CaseIterable, CodableData {
    case ethSign = "eth_sign"
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
