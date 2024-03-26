//
//  SocketMessage.swift
//  metamask-ios-sdk
//

import Foundation

enum DecodingError: Error {
    case invalidMessage
}

public struct SocketMessage<T: CodableData>: CodableData, Mappable {
    public let id: String
    public let message: T
    
    public init(id: String, message: T) {
        self.id = id
        self.message = message
    }

    public func socketRepresentation() -> NetworkData {
        [
            "id": id,
            "message": try? message.socketRepresentation(),
        ]
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
