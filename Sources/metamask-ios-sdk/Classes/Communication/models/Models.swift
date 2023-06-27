//
//  Connection.swift
//

import SocketIO
import Foundation

public typealias NetworkData = SocketData
public typealias RequestTask = Task<Any, Never>
public typealias CodableData = Codable & SocketData

struct OriginatorInfo: CodableData {
    let title: String?
    let url: String?
    let platform: String?
    let apiVersion: String?

    func socketRepresentation() -> NetworkData {
        [
            "title": title,
            "url": url,
            "platform": platform,
            "apiVersion": apiVersion,
        ]
    }
}

struct Message<T: CodableData>: CodableData {
    let id: String
    let message: T

    func socketRepresentation() -> NetworkData {
        [
            "id": id,
            "message": try? message.socketRepresentation(),
        ]
    }

    static func message(from message: [String: Any]) -> Message<T>? {
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

struct RequestInfo: CodableData {
    let type: String
    let originator: OriginatorInfo
    let originatorInfo: OriginatorInfo

    func socketRepresentation() -> NetworkData {
        ["type": type,
         "originator": originator.socketRepresentation(), // Backward compatibility with MetaMask mobile
         "originatorInfo": originatorInfo.socketRepresentation()]
    }
}
