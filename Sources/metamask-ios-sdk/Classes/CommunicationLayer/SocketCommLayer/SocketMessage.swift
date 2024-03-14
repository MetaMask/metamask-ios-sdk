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
    
    public func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            Logging.error("Message:: Error encoding JSON: \(error)")
            return nil
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
