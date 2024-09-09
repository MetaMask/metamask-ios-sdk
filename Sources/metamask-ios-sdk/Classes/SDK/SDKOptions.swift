//
//  SDKOptions.swift
//  metamask-ios-sdk
//

import Foundation

public struct SDKOptions {
    public let infuraAPIKey: String
    public let readonlyRPCMap: [String: String]

    public init(infuraAPIKey: String, readonlyRPCMap: [String: String] = [:]) {
        self.infuraAPIKey = infuraAPIKey
        self.readonlyRPCMap = readonlyRPCMap
    }
}
