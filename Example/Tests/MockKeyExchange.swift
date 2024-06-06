//
//  MockKeyExchange.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk

class MockKeyExchange: KeyExchange {
    override func decryptMessage(_ message: String) throws -> String {
        return "decryptedMessage"
    }
}
