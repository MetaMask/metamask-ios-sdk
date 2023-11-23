//
//  BatchRequest.swift
//  metamask-ios-sdk
//

import Foundation

public struct BatchRequest<T: CodableData>: CodableData {
    public var id: String
    var method: String = EthereumMethod.metamaskBatch.rawValue
    public var params: [EthereumRequest<T>]
    
    public var methodType: EthereumMethod {
        EthereumMethod(rawValue: method) ?? .unknownMethod
    }
    
    public init(id: String = TimestampGenerator.timestamp(),
                params: [EthereumRequest<T>]) {
        self.params = params
        self.id = id
    }
    
    public func socketRepresentation() -> NetworkData {
        [
            "id": id,
            "method": method,
            "parameters": params.socketRepresentation()
        ]
    }
}
