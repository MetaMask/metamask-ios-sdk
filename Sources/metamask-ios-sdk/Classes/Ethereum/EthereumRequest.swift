//
//  EthereumRequest.swift
//

import Foundation

public struct EthereumRequest<T: CodableData>: CodableData {
    public var id: String?
    public let method: String
    public var params: [T]

    public init(id: String? = nil, method: String, params: [T] = [""]) {
        self.id = id
        self.method = method
        self.params = params
    }

    public func socketRepresentation() -> NetworkData {
        [
            "id": id ?? "",
            "method": method,
            "parameters": params.socketRepresentation()
        ]
    }
}
