//
//  KeyExchange.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import Foundation

public enum KeyExchangeStep: String, Codable {
    case none = "none"
    case start = "key_handshake_start"
    case ack = "key_handshake_ACK"
    case syn = "key_handshake_SYN"
    case synack = "key_handshake_SYNACK"
}

public enum KeyExchangeError: Error {
    case keysNotExchanged
    case encodingError
}

public struct KeyExchangeMessage: Codable {
    public let type: KeyExchangeStep
    public var publicKey: String?
}

/*
 A module for handling key exchange between client and server
 The key exchange sequence is defined as:
 none -> syn -> synack -> ack
 */

public class KeyExchange {
    private let privateKey: String
    public let publicKey: String
    public var theirPublicKey: String?
    
    private let encyption: Crypto.Type
    public private(set) var keysExchanged: Bool = false
    private var keyExchangeStep: KeyExchangeStep = .none
    
    public var handleKeyExchangeMessage: ((KeyExchangeMessage) -> Void)?
    public var updateKeyExchangeStep: ((KeyExchangeStep, String?) -> Void)?
    
    public init(encryption: Crypto.Type = ECIES.self) {
        self.encyption = encryption
        self.privateKey = encyption.generatePrivateKey()
        self.publicKey = encyption.publicKey(from: privateKey)
        setupKeyExchangeHandling()
    }
    
    private func setupKeyExchangeHandling() {
        handleKeyExchangeMessage = { [weak self, keysExchanged] message in
            if keysExchanged { return }
            
            switch message.type {
            case .syn:
                self?.keyExchangeStep = .ack
                
                if self?.theirPublicKey == nil, message.publicKey != nil {
                    self?.setTheirPublicKey(message.publicKey)
                }
                
                self?.updateKeyExchangeStep?(.synack, self?.publicKey)
            case .synack:
                self?.setTheirPublicKey(message.publicKey)
                self?.updateKeyExchangeStep?(.ack, nil)
                self?.keysExchanged = true
            case .ack:
                self?.keysExchanged = true
            default:
                break
            }
        }
    }
    
    public func keyExchangeMessage(with type: KeyExchangeStep) -> KeyExchangeMessage {
        KeyExchangeMessage(
            type: type,
            publicKey: publicKey
        )
    }
    
    public func setTheirPublicKey(_ publicKey: String?) {
        theirPublicKey = publicKey
    }
    
    public func encryptMessage(_ message: Codable) throws -> String {
        guard let theirPublicKey = theirPublicKey else {
            throw KeyExchangeError.keysNotExchanged
        }
        
        guard let encodedData = try? JSONEncoder().encode(message) else {
            throw KeyExchangeError.encodingError
        }
        
        guard let jsonString = String(
            data: encodedData,
            encoding: .utf8) else {
            throw KeyExchangeError.encodingError
        }
        
        return encyption.encrypt(
            jsonString,
            publicKey: theirPublicKey
        )
    }
    
    public func decryptMessage(_ message: String) throws -> String {
        guard theirPublicKey != nil else {
            throw KeyExchangeError.keysNotExchanged
        }
        
        return encyption.decrypt(
            message,
            privateKey: privateKey
        )
    }
}
