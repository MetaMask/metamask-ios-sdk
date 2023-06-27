//
//  SessionConfig.swift
//  metamask-ios-sdk
//

import Foundation

class SessionConfig: Codable {
    let sessionId: String
    let expiry: Date
    
    var isValid: Bool {
        expiry > Date()
    }
    
    init(sessionId: String, expiry: Date) {
        self.sessionId = sessionId
        self.expiry = expiry
    }
}
