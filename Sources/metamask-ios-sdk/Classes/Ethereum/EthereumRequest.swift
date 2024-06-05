//
//  EthereumRequest.swift
//

import Foundation

public struct EthereumRequest<T: CodableData>: RPCRequest {
    public var id: String
    public let method: String
    public var params: T

    public var methodType: EthereumMethod {
        EthereumMethod(rawValue: method) ?? .unknownMethod
    }

    public init(id: String = TimestampGenerator.timestamp(),
                method: String,
                params: T = "") {
        self.id = id
        self.method = method
        self.params = params
    }

    public init(id: String = TimestampGenerator.timestamp(),
                method: EthereumMethod,
                params: T = "") {
        self.id = id
        self.method = method.rawValue
        self.params = params
    }

    public func socketRepresentation() -> NetworkData {
        [
            "id": id,
            "method": method,
            "parameters": try? params.socketRepresentation()
        ]
    }
}
