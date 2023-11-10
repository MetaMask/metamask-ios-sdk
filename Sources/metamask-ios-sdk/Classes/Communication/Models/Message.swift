//
//  Message.swift
//  metamask-ios-sdk
//

import Foundation

enum DecodingError: Error {
    case invalidMessage
}

public struct Message<T: CodableData>: CodableData {
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

    public static func message(from message: [String: Any]) throws -> Message<T> {
        do {
            let json = try JSONSerialization.data(withJSONObject: message)
            let message = try JSONDecoder().decode(Message<T>.self, from: json)
            return message
        } catch {
            Logging.error("Message \(message) could not be decoded: \(error.localizedDescription)")
            throw DecodingError.invalidMessage
        }
    }
}
