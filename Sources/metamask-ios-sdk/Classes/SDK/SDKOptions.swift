//
//  SDKOptions.swift
//  metamask-ios-sdk
//

import Foundation

public struct SDKOptions {
    public let infuraAPIKey: String
    
    public init(infuraAPIKey: String) {
        self.infuraAPIKey = infuraAPIKey
    }
}
