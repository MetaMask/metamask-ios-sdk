//
//  KeyExchange.swift
//

import SocketIO
import Foundation

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
    private var privateKey: String

    public var pubkey: String
    public private(set) var theirPublicKey: String?

    private let encyption: Crypto.Type
    var keysExchanged: Bool = false

    public init(encryption: Crypto.Type = Ecies.self) {
        encyption = encryption
        privateKey = encyption.generatePrivateKey()
        pubkey = encyption.publicKey(from: privateKey)
    }

    func reset() {
        keysExchanged = false
        theirPublicKey = nil
        privateKey = encyption.generatePrivateKey()
        pubkey = encyption.publicKey(from: privateKey)
    }

    func nextMessage(_ message: KeyExchangeMessage) -> KeyExchangeMessage? {
        if let publicKey = message.pubkey {
            setTheirPublicKey(publicKey)
            keysExchanged = true
        }

        guard let nextStep = nextStep(message.type) else {
            return nil
        }

        return KeyExchangeMessage(
            type: nextStep,
            pubkey: pubkey
        )
    }

    func nextStep(_ step: KeyExchangeType) -> KeyExchangeType? {
        switch step {
        case .start: return .syn
        case .syn: return .synack
        case .synack: return .ack
        case .ack: return nil
        }
    }

    func message(type: KeyExchangeType) -> KeyExchangeMessage {
        KeyExchangeMessage(
            type: type,
            pubkey: pubkey
        )
    }

    func setTheirPublicKey(_ publicKey: String?) {
        theirPublicKey = publicKey
    }

    static func isHandshakeRestartMessage(_ message: [String: Any]) -> Bool {
        guard
            let message = message["message"] as? [String: Any],
            let type = message["type"] as? String,
            let exchangeType = KeyExchangeType(rawValue: type),
            exchangeType == .start
        else { return false }
        return true
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
            encoding: .utf8
        ) else {
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
