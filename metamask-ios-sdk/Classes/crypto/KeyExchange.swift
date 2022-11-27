//
//  KeyExchange.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import Foundation
import SocketIO

public enum KeyExchangeStep: String, Codable {
    case none = "none"
    case ack = "key_handshake_ACK"
    case syn = "key_handshake_SYN"
    case synack = "key_handshake_SYNACK"
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try? container.decode(String.self)
        switch status {
              case "none": self = .none
              case "key_handshake_ACK": self = .ack
              case "key_handshake_SYN": self = .syn
              case "key_handshake_SYNACK": self = .synack
              default:
                 self = .none
          }
      }
}

public enum KeyExchangeError: Error {
    case keysNotExchanged
    case encodingError
}

public struct KeyExchangeMessage: CodableSocketData {
    public let type: KeyExchangeStep
    public let publicKey: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case publicKey = "pubkey"
    }
    
    public func socketRepresentation() -> SocketData {
        ["type": type.rawValue, "pubkey": publicKey]
    }
}

/*
 A module for handling key exchange between client and server
 The key exchange sequence is defined as:
 syn -> synack -> ack
 */

public class KeyExchange {
    private let privateKey: String
    public let publicKey: String
    public var theirPublicKey: String?
    
    private let encyption: Crypto.Type
    public private(set) var keysExchanged: Bool = false
    
    public init(encryption: Crypto.Type = ECIES.self) {
        self.encyption = encryption
        self.privateKey = encyption.generatePrivateKey()
        self.publicKey = encyption.publicKey(from: privateKey)
    }
    
    func nextKeyExchangeMessage(_ message: KeyExchangeMessage) -> KeyExchangeMessage? {
        
        Logging.log("Keys exchange status: \(message.type)")
        
        switch message.type {
        case .syn:
            if let publicKey = message.publicKey {
                setTheirPublicKey(publicKey)
            }
            
            return KeyExchangeMessage(
                type: .synack,
                publicKey: publicKey)
            
        case .synack:
            
            if let publicKey = message.publicKey {
                setTheirPublicKey(publicKey)
            }
            
            keysExchanged = true
            Logging.log("Keys have been exchanged")
            return KeyExchangeMessage(
                type: .ack,
                publicKey: publicKey)
            
        case .ack:
            keysExchanged = true
            Logging.log("Keys exchange complete!")
            return nil
            
        default:
            return nil
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
    
    public func encryptMessage<T: Codable & SocketData>(_ message: T) throws -> String {
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
