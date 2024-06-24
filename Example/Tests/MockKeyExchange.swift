//
//  MockKeyExchange.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk

class MockKeyExchange: KeyExchange {
    var throwEncryptError = false
    var throwDecryptError = false
    var encryptCalled = false
    var decryptCalled = false
    
    override func decryptMessage(_ message: String) throws -> String {
        if throwDecryptError {
            throw CryptoError.decryptionFailure
        }
        
        decryptCalled = true
        
        return "decrypted \(message)"
    }
    
    override func encrypt(_ message: String) throws -> String {
        if throwEncryptError {
            throw CryptoError.encryptionFailure
        }
        encryptCalled = true
        
        return "encrypted \(message)"
    }
    
    override func encryptMessage<T: Codable>(_ message: T) throws -> String {
        if throwEncryptError {
            throw CryptoError.encryptionFailure
        }
        
        encryptCalled = true
        
        return "encrypted \(message)"
    }
}
