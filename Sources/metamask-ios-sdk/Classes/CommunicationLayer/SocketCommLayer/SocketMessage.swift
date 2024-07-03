//
//  SocketMessage.swift
//  metamask-ios-sdk
//

import Foundation

enum DecodingError: Error {
    case invalidMessage
}

public struct SocketMessage<T: Codable>: CodableData, Mappable {
    public let id: String
    public var ackId: String?
    public let message: T
    public var clientType: String = "dapp"

    public init(id: String, message: T, ackId: String? = nil, clientType: String = "dapp") {
        self.id = id
        self.message = message
        self.ackId = ackId
        self.clientType = clientType
    }
    
    // Custom initializer for decoding
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        ackId = try container.decodeIfPresent(String.self, forKey: .ackId)
        message = try container.decode(T.self, forKey: .message)
        clientType = try container.decodeIfPresent(String.self, forKey: .clientType) ?? "dapp"
    }
    
    // Custom method for encoding
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ackId, forKey: .ackId)
        try container.encode(message, forKey: .message)
        try container.encode(clientType, forKey: .clientType)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case ackId
        case message
        case clientType
    }

    public func socketRepresentation() -> NetworkData {
        if let ack = ackId {
            [
                "id": id,
                "ackId": ack,
                "clientType": clientType,
                "message": try? (message as? CodableData)?.socketRepresentation()
            ]
        } else {
            [
                "id": id,
                "clientType": clientType,
                "message": try? (message as? CodableData)?.socketRepresentation()
            ]
        }
    }

    func toDictionary() -> [String: Any]? {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(self)
            guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                print("Error converting JSON data to dictionary")
                Logging.error("Message:: Error converting JSON data to dictionary")
                return nil
            }
            return jsonObject
        } catch {
            print("Error encoding JSON: \(error)")
            Logging.error("Message:: Error encoding JSON: \(error)")
            return nil
        }
    }

    public static func message(from message: [String: Any]) throws -> SocketMessage<T> {
        do {
            let json = try JSONSerialization.data(withJSONObject: message)
            let message = try JSONDecoder().decode(SocketMessage<T>.self, from: json)
            return message
        } catch {
            Logging.error("Message \(message) could not be decoded: \(error.localizedDescription)")
            throw DecodingError.invalidMessage
        }
    }
}
