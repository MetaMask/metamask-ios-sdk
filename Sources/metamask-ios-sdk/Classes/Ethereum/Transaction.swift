//
//  Transaction.swift
//

import Foundation

public struct Transaction: CodableData {
    public var to: String
    public let from: String
    public var value: String

    public init(to: String, from: String, value: String) {
        self.to = to
        self.from = from
        self.value = value
    }

    public func socketRepresentation() -> NetworkData {
        [
            "to": to,
            "from": from,
            "value": value
        ]
    }
}
