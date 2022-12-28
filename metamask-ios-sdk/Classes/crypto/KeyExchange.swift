//
//  KeyExchange.swift
//

import Foundation
import SocketIO

public enum KeyExchangeType: String, Codable {
    case start = "key_handshake_start"
    case ack = "key_handshake_ACK"
    case syn = "key_handshake_SYN"
    case synack = "key_handshake_SYNACK"
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try? container.decode(String.self)
        switch status {
            case "key_handshake_start": self = .start
            case "key_handshake_ACK": self = .ack
            case "key_handshake_SYN": self = .syn
            case "key_handshake_SYNACK": self = .synack
            default:
                self = .ack
          }
      }
}

public enum KeyExchangeError: Error {
    case keysNotExchanged
    case encodingError
}

public struct KeyExchangeMessage: CodableData {
    public let type: KeyExchangeType
    public let pubkey: String?
    
    public func socketRepresentation() -> NetworkData {
        ["type": type.rawValue, "pubkey": pubkey]
    }
}

/*
 A module for handling key exchange between client and server
 The key exchange sequence is defined as:
 syn -> synack -> ack
 */

public class KeyExchange {
    private let privateKey: String
    
    public let pubkey: String
    public private(set) var theirPublicKey: String?
    
    private let encyption: Crypto.Type
    var keysExchanged: Bool = false
    
    public init(encryption: Crypto.Type = Ecies.self) {
        self.encyption = encryption
        self.privateKey = encyption.generatePrivateKey()
        self.pubkey = encyption.publicKey(from: privateKey)
    }
    
    func restart() {
        keysExchanged = false
    }
    
    func nextMessage(_ message: KeyExchangeMessage) -> KeyExchangeMessage? {
        if message.type == .synack || message.type == .ack {
            keysExchanged = true
        }
        
        if let publicKey = message.pubkey {
            setTheirPublicKey(publicKey)
        }
        
        guard let nextStep = nextStep(message.type) else {
            return nil
        }
        
        return KeyExchangeMessage(
            type: nextStep,
            pubkey: pubkey)
    }
    
    func nextStep(_ step: KeyExchangeType) -> KeyExchangeType? {
        switch step {
        case .start: return .syn
        case .syn: return .synack
        case .synack: return .ack
        case .ack: return nil
        }
    }
    
    public func message(type: KeyExchangeType) -> KeyExchangeMessage {
        KeyExchangeMessage(
            type: type,
            pubkey: pubkey
        )
    }
    
    public func setTheirPublicKey(_ publicKey: String?) {
        theirPublicKey = publicKey
    }
    
    public func encryptMessage<T: CodableData>(_ message: T) throws -> String {
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
        
        return try encyption.encrypt(
            jsonString,
            publicKey: theirPublicKey
        )
    }
    
    public func decryptMessage(_ message: String) throws -> String {
        guard theirPublicKey != nil else {
            throw KeyExchangeError.keysNotExchanged
        }
        
        return try encyption.decrypt(
            message,
            privateKey: privateKey
        )
    }
}
