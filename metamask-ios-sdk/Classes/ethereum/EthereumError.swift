//
//  EthereumError.swift
//

import Foundation

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
