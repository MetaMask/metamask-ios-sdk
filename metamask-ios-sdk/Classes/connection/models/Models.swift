//
//  Connection.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import SocketIO
import Foundation

typealias CodableSocketData = CodableData

struct OriginatorInfo: CodableSocketData {
    let title: String
    let url: String
    
    func socketRepresentation() -> NetworkData {
        ["title": title, "url": url]
    }
}

struct Message<T: CodableSocketData>: CodableSocketData {
    let id: String
    let message: T
    
    func socketRepresentation() -> NetworkData {
        [
            "id": id,
            "message": try? message.socketRepresentation()
        ]
    }
    
    static func message(from message: [String: Any]) -> Message<T>? {
        do {
            let json = try JSONSerialization.data(withJSONObject: message)
            let message = try JSONDecoder().decode(Message<T>.self, from: json)
            return message
        } catch {
            Logging.error(error.localizedDescription)
        }
        return nil
    }
}

struct RequestInfo: CodableSocketData {
    let type: String
    let originator: OriginatorInfo
    
    func socketRepresentation() -> NetworkData {
        ["type": type, "originator": originator.socketRepresentation()]
    }
}
