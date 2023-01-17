//
//  Transaction.swift
//

import Foundation

public struct Transaction: CodableData {
    public let to: String
    public let from: String
    public let value: String
    public let data: String

    public init(to: String, from: String, value: String, data: String = "") {
        self.to = to
        self.from = from
        self.value = value
        self.data = data
    }

    public func socketRepresentation() -> NetworkData {
        [
            "to": to,
            "from": from,
            "value": value,
            "data": data
        ]
    }
}
