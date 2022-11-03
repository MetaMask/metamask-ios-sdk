//
//  KeyExchange.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import Foundation

public enum KeyExchangeType: String, Codable {
    case handshakeStart = "key_handshake_start"
    case handshakeAcknowledge = "key_handshake_ACK"
    case handshakeSynchronise = "key_handshake_SYN"
    case handshakeSynchroniseAcknowledgement = "key_handshake_SYNACK"
}

public struct KeyExchangeMessage: Codable {
    public let type: KeyExchangeType
    public let publicKey: String
}

public class KeyExchange {
    private let privateKey: String
    public let publicKey: String
    public var theirPublicKey: String?
    
    public init() {
        privateKey = ECIES.generatePrivateKey()
        publicKey = ECIES.publicKey(from: privateKey)
    }
    
    public func keyExchangeMessage(with type: KeyExchangeType) -> KeyExchangeMessage {
        KeyExchangeMessage(
            type: type,
            publicKey: publicKey
        )
    }
    
    public func setTheirPublicKey(_ publicKey: String) {
        theirPublicKey = publicKey
    }
    
    public func encryptMessage(_ message: Codable) -> String {
        guard let theirPublicKey = theirPublicKey else {
            assertionFailure(
                "Their public key has not been set",
                file: #file,
                line: #line)
            return ""
        }
        
        guard let encodedData = try? JSONEncoder().encode(message) else {
            assertionFailure(
                "Message object could not be encoded",
                file: #file,
                line: #line)
            return ""
        }
        
        guard let jsonString = String(
            data: encodedData,
            encoding: .utf8) else {
            assertionFailure(
                "Encoded message could not be stringified",
                file: #file,
                line: #line)
            return ""
        }
        
        return ECIES.encrypt(
            jsonString,
            publicKey: theirPublicKey
        )
    }
    
    public func decryptMessage(_ message: String) -> String {
        ECIES.decrypt(
            message,
            privateKey: privateKey
        )
    }
}
