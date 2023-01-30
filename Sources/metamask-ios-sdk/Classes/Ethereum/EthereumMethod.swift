//
//  EthereumMethod.swift
//  metamask-ios-sdk
//

import Foundation

public enum EthereumMethod: String, CaseIterable, CodableData {
    case ethSign = "eth_sign"
    case web3Sha = "web3_sha3"
    case ethCall = "eth_call"
    case ethChainId = "eth_chainId"
    case ethGetCode = "eth_getCode"
    case ethAccounts = "eth_accounts"
    case ethGasPrice = "eth_gasPrice"
    case personalSign = "personal_sign"
    case ethGetBalance = "eth_getBalance"
    case watchAsset = "wallet_watchAsset"
    case ethBlockNumber = "eth_blockNumber"
    case ethEstimateGas = "eth_estimateGas"
    case ethGetStorageAt = "eth_getStorageAt"
    case ethSignTypedData = "eth_signTypedData"
    case ethGetBlockByHash = "eth_getBlockByHash"
    case web3ClientVersion = "web3_clientVersion"
    case ethRequestAccounts = "eth_requestAccounts"
    case ethSignTransaction = "eth_signTransaction"
    case ethSendTransaction = "eth_sendTransaction"
    case ethSignTypedDataV3 = "eth_signTypedData_v3"
    case ethSignTypedDataV4 = "eth_signTypedData_v4"
    case addEthereumChain = "wallet_addEthereumChain"
    case metaMaskChainChanged = "metamask_chainChanged"
    case ethSendRawTransaction = "eth_sendRawTransaction"
    case switchEthereumChain = "wallet_switchEthereumChain"
    case ethGetTransactionCount = "eth_getTransactionCount"
    case metaMaskAccountsChanged = "metamask_accountsChanged"
    case ethGetTransactionByHash = "eth_getTransactionByHash"
    case ethGetTransactionReceipt = "eth_getTransactionReceipt"
    case getMetamaskProviderState = "metamask_getProviderState"
    case ethGetBlockTransactionCountByHash = "eth_getBlockTransactionCountByHash"
    case ethGetBlockTransactionCountByNumber = "eth_getBlockTransactionCountByNumber"
    case unknownMethod = "unknown"

    static func requiresDeeplinking(_ method: EthereumMethod) -> Bool {
        let deeplinkMethods: [EthereumMethod] = [
            .ethSign,
            .watchAsset,
            .personalSign,
            .ethSignTypedData,
            .ethRequestAccounts,
            .ethSendTransaction,
            .ethSignTypedDataV3,
            .ethSignTypedDataV4,
            .addEthereumChain,
            .switchEthereumChain
        ]

        return deeplinkMethods.contains(method)
    }

    static func isResultMethod(_ method: EthereumMethod) -> Bool {
        let resultMethods: [EthereumMethod] = [
            .ethSign,
            .ethChainId,
            .personalSign,
            .watchAsset,
            .ethSignTypedData,
            .ethRequestAccounts,
            .ethSignTransaction,
            .ethSendTransaction,
            .ethSignTypedDataV3,
            .ethSignTypedDataV4,
            .addEthereumChain,
            .switchEthereumChain,
            .getMetamaskProviderState
        ]

        return resultMethods.contains(method)
    }
}
