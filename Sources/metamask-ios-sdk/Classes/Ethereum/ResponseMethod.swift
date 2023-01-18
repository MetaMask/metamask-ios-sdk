//
//  ResponseMethod.swift
//  metamask-ios-sdk
//

import Foundation

enum ResponseMethod: String {
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
    case getMetamaskProviderState = "metamask_getProviderState"
}
