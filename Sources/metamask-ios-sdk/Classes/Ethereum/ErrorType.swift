//
//  ErrorType.swift
//  metamask-ios-sdk
//

import Foundation

public enum ErrorType: Int {
    // MARK: Ethereum Provider
    case userRejectedRequest = 4001 // Ethereum Provider User Rejected Request
    case unauthorisedRequest = 4100 // Ethereum Provider User Rejected Request
    case unsupportedMethod = 4200 // Ethereum Provider Unsupported Method
    case disconnected = 4900 // Ethereum Provider Not Connected
    case chainDisconnected = 4901 // Ethereum Provider Chain Not Connected
    case unrecognizedChainId = 4902 // Unrecognized chain ID. Try adding the chain using wallet_addEthereumChain first
    
    // MARK: Ethereum RPC
    case invalidInput = -32000 // JSON RPC 2.0 Server error
    case transactionRejected = -32003 // Ethereum JSON RPC Transaction Rejected
    case invalidRequest = -32600 // JSON RPC 2.0 Invalid Request
    case invalidMethodParameters = -32602 // JSON RPC 2.0 Invalid Parameters
    case internalServerError = -32603 // Could be one of many outcomes
    case parseError = -32700 // JSON RPC 2.0 Parse error
    case unknown = -1 // check RequestError.code instead
}
