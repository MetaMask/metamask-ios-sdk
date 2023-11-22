//
//  BatchRequest.swift
//  metamask-ios-sdk
//

import Foundation

public struct BatchRequest<T: CodableData>: CodableData {
    public var id: String = UUID().uuidString
    public var method: String = EthereumMethod.metamaskBatch.rawValue
    public var params: [EthereumRequest<T>]
    
    public var methodType: EthereumMethod {
        EthereumMethod(rawValue: method) ?? .unknownMethod
    }
    
    public init(params: [EthereumRequest<T>]) {
        self.params = params
    }
}
