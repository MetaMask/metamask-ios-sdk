//
//  Connection.swift
//

import SocketIO
import Foundation

public typealias NetworkData = SocketData
public typealias RequestTask = Task<Any, Never>
public typealias CodableData = Codable & SocketData

public struct OriginatorInfo: CodableData {
    public let title: String?
    public let url: String?
    public let platform: String?
    public let apiVersion: String?

    public func socketRepresentation() -> NetworkData {
        [
            "title": title,
            "url": url,
            "platform": platform,
            "apiVersion": apiVersion,
        ]
    }
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

    public static func message(from message: [String: Any]) -> Message<T>? {
        do {
            let json = try JSONSerialization.data(withJSONObject: message)
            let message = try JSONDecoder().decode(Message<T>.self, from: json)
            return message
        } catch {
            Logging.error("Message \(message) could not be decoded: \(error.localizedDescription)")
        }
        return nil
    }
}

public struct RequestInfo: CodableData {
    public let type: String
    public let originator: OriginatorInfo
    public let originatorInfo: OriginatorInfo

    public func socketRepresentation() -> NetworkData {
        ["type": type,
         "originator": originator.socketRepresentation(), // Backward compatibility with MetaMask mobile
         "originatorInfo": originatorInfo.socketRepresentation()]
    }
}
