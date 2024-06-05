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
    case ethSendTransaction = "eth_sendTransaction"
    case ethSignTypedDataV3 = "eth_signTypedData_v3"
    case ethSignTypedDataV4 = "eth_signTypedData_v4"
    case addEthereumChain = "wallet_addEthereumChain"
    case metamaskBatch = "metamask_batch"
    case metamaskOpen = "metamask_open"
    case personalEcRecover = "personal_ecRecover"
    case walletRevokePermissions = "wallet_revokePermissions"
    case walletRequestPermissions  = "wallet_requestPermissions"
    case walletGetPermissions = "wallet_getPermissions"
    case metamaskConnectWith = "metamask_connectwith"
    case metaMaskChainChanged = "metamask_chainChanged"
    case ethSendRawTransaction = "eth_sendRawTransaction"
    case switchEthereumChain = "wallet_switchEthereumChain"
    case ethGetTransactionCount = "eth_getTransactionCount"
    case metaMaskConnectSign = "metamask_connectSign"
    case metaMaskAccountsChanged = "metamask_accountsChanged"
    case ethGetTransactionByHash = "eth_getTransactionByHash"
    case ethGetTransactionReceipt = "eth_getTransactionReceipt"
    case getMetamaskProviderState = "metamask_getProviderState"
    case ethGetBlockTransactionCountByHash = "eth_getBlockTransactionCountByHash"
    case ethGetBlockTransactionCountByNumber = "eth_getBlockTransactionCountByNumber"
    case unknownMethod = "unknown"

    static func requiresAuthorisation(_ method: EthereumMethod) -> Bool {
        let methods: [EthereumMethod] = [
            .ethSign,
            .watchAsset,
            .metamaskOpen,
            .personalEcRecover,
            .walletRequestPermissions,
            .walletRevokePermissions,
            .walletGetPermissions,
            .personalSign,
            .metamaskBatch,
            .metaMaskConnectSign,
            .metamaskConnectWith,
            .ethSignTypedData,
            .ethRequestAccounts,
            .ethSendTransaction,
            .ethSignTypedDataV3,
            .ethSignTypedDataV4,
            .addEthereumChain,
            .switchEthereumChain
        ]

        return methods.contains(method)
    }

    static func isReadOnly(_ method: EthereumMethod) -> Bool {
        !requiresAuthorisation(method)
    }

    static func isResultMethod(_ method: EthereumMethod) -> Bool {
        let resultMethods: [EthereumMethod] = [
            .ethSign,
            .watchAsset,
            .ethChainId,
            .personalSign,
            .metamaskBatch,
            .walletRevokePermissions,
            .walletGetPermissions,
            .walletRequestPermissions,
            .metaMaskConnectSign,
            .metamaskConnectWith,
            .ethSignTypedData,
            .ethRequestAccounts,
            .ethSendTransaction,
            .ethSignTypedDataV3,
            .ethSignTypedDataV4,
            .addEthereumChain,
            .switchEthereumChain,
            .getMetamaskProviderState
        ]

        return resultMethods.contains(method)
    }

    static func isConnectMethod(_ method: EthereumMethod) -> Bool {
        let connectMethods: [EthereumMethod] = [
            .metaMaskConnectSign,
            .metamaskConnectWith
        ]
        return connectMethods.contains(method)
    }
}
