//
//  KeyExchange.swift
//

import SocketIO
import Foundation

public enum KeyExchangeType: String, Mappable {
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

public struct KeyExchangeMessage: CodableData, Mappable {
    public let type: KeyExchangeType
    public let pubkey: String?
    public var v: Int?
    public var clientType: String? = "dapp"

    public init(type: KeyExchangeType, pubkey: String?, v: Int? = 2, clientType: String? = "dapp") {
        self.type = type
        self.pubkey = pubkey
        self.clientType = clientType
        self.v = v
    }

    // Custom initializer for decoding
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(KeyExchangeType.self, forKey: .type)
        pubkey = try container.decodeIfPresent(String.self, forKey: .pubkey)
        v = try container.decodeIfPresent(Int.self, forKey: .v) ?? 2
        clientType = try container.decodeIfPresent(String.self, forKey: .clientType) ?? "dapp"
    }

    // Custom method for encoding
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(pubkey, forKey: .pubkey)
        try container.encode(v, forKey: .v)
        try container.encode(clientType, forKey: .clientType)
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case pubkey
        case v
        case clientType
    }
    
    public func socketRepresentation() -> NetworkData {
        ["type": type.rawValue, "pubkey": pubkey, "v": v, "clientType": clientType]
    }
}

/*
 A module for handling key exchange between client and server
 The key exchange sequence is defined as:
 syn -> synack -> ack
 */

public class KeyExchange {
    private var privateKey: String
    public var pubkey: String
    public private(set) var theirPublicKey: String?

    private let storage: SecureStore
    private let encyption: Crypto.Type
    var keysExchanged: Bool = false
    var isKeysExchangedViaV2Protocol: Bool = false
    private let privateKeyStorageKey = "MM_SDK_PRIV_KEY"
    private let theirPubliKeyStorageKey = "MM_SDK_THEIR_PUB_KEY"

    public init(encryption: Crypto.Type = Ecies.self, storage: SecureStore) {
        self.storage = storage
        self.encyption = encryption

        if let storedPrivateKey = storage.string(for: privateKeyStorageKey) {
            Logging.log("KeyExchange:: using stored private key")
            self.privateKey = storedPrivateKey
            
            if let theirPubKey = storage.string(for: theirPubliKeyStorageKey) {
                self.theirPublicKey = theirPubKey
                
                // wallet already has keys
                keysExchanged = true
                isKeysExchangedViaV2Protocol = true
            }
        } else {
            Logging.log("KeyExchange:: generating new private key")
            privateKey = encyption.generatePrivateKey()
        }
        
        do {
            pubkey = try encyption.publicKey(from: privateKey)
        } catch {
            pubkey = ""
        }
    }

    public func reset() {
        keysExchanged = false
        theirPublicKey = nil
        privateKey = ""
        isKeysExchangedViaV2Protocol = false
        
        storage.deleteData(for: privateKeyStorageKey)
        storage.deleteData(for: theirPubliKeyStorageKey)
        privateKey = encyption.generatePrivateKey()
        
        do {
            pubkey = try encyption.publicKey(from: privateKey)
        } catch {
            pubkey = ""
        }
    }

    public func nextMessage(_ message: KeyExchangeMessage) -> KeyExchangeMessage? {
        if message.type == .start {
            keysExchanged = false
        }

        if 
            let publicKey = message.pubkey,
            !publicKey.isEmpty {
            setTheirPublicKey(publicKey)
            keysExchanged = true
            
            if message.v == 2 {
                self.storage.save(string: privateKey, key: privateKeyStorageKey)
                self.storage.save(string: publicKey, key: theirPubliKeyStorageKey)
                isKeysExchangedViaV2Protocol = true
            }
        }

        guard let nextStep = nextStep(message.type) else {
            return nil
        }

        return KeyExchangeMessage(
            type: nextStep,
            pubkey: pubkey
        )
    }

    public func nextStep(_ step: KeyExchangeType) -> KeyExchangeType? {
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
        if let theirPubKey = publicKey {
            theirPublicKey = theirPubKey
            storage.save(string: theirPubKey, key: theirPubliKeyStorageKey)
        }
    }

    public static func isHandshakeRestartMessage(_ message: [String: Any]) -> Bool {
        guard
            let message = message["message"] as? [String: Any],
            let type = message["type"] as? String,
            let exchangeType = KeyExchangeType(rawValue: type),
            exchangeType == .start
        else { return false }
        return true
    }

    public func encryptMessage<T: Codable>(_ message: T) throws -> String {
        guard let theirPublicKey = theirPublicKey else {
            throw KeyExchangeError.keysNotExchanged
        }

        guard let encodedData = try? JSONEncoder().encode(message) else {
            throw KeyExchangeError.encodingError
        }

        guard let jsonString = String(
            data: encodedData,
            encoding: .utf8
        ) else {
            throw KeyExchangeError.encodingError
        }

        return try encyption.encrypt(
            jsonString,
            publicKey: theirPublicKey
        )
    }

    public func encrypt(_ message: String) throws -> String {
        guard let theirPublicKey = theirPublicKey else {
            throw KeyExchangeError.keysNotExchanged
        }

        return try encyption.encrypt(
            message,
            publicKey: theirPublicKey
        )
    }

    public func decryptMessage(_ message: String) throws -> String {
        guard theirPublicKey != nil else {
            throw KeyExchangeError.keysNotExchanged
        }

        let decryted = try encyption.decrypt(
            message,
            privateKey: privateKey
        ).trimEscapingChars()
        return decryted
    }
}

extension KeyExchange {
    static let live = Dependencies.shared.keyExchange
}
