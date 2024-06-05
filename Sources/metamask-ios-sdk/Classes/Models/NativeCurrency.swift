//
//  NativeCurrency.swift
//  metamask-ios-sdk

import Foundation

public struct NativeCurrency: CodableData {
    public let name: String?
    public let symbol: String
    public let decimals: Int

    public init(name: String?, symbol: String, decimals: Int) {
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
    }

    public func socketRepresentation() -> NetworkData {
        [
            "name": name ?? "",
            "symbol": symbol,
            "decimals": decimals
        ]
    }
}
