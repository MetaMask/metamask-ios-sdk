//
//  SessionConfig.swift
//  metamask-ios-sdk
//

import Foundation

public class SessionConfig: Codable, Equatable {
    public static func == (lhs: SessionConfig, rhs: SessionConfig) -> Bool {
        lhs.sessionId == rhs.sessionId && lhs.expiry == rhs.expiry
    }
    
    let sessionId: String
    let expiry: Date
    
    public var isValid: Bool {
        expiry > Date()
    }
    
    public init(sessionId: String, expiry: Date) {
        self.sessionId = sessionId
        self.expiry = expiry
    }
}
