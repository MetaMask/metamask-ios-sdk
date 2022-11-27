//
//  Connection.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import SocketIO
import Foundation

typealias CodableSocketData = Codable & SocketData

struct OriginatorInfo: CodableSocketData {
    let title: String
    let url: String
    
    func socketRepresentation() -> CodableSocketData {
        ["title": title, "url": url]
    }
}

struct Message<T: CodableSocketData>: CodableSocketData {
    let id: String
    let message: T
    
    func socketRepresentation() -> SocketData {
        [
            "id": id,
            "message": try? message.socketRepresentation()
        ]
    }
    
    static func keyExchangeMessage(from json: String) -> Message<KeyExchangeMessage>? {
        guard
            let jsonData = json.data(using: .utf8),
            let model = try? JSONDecoder().decode(Message<KeyExchangeMessage>.self, from: jsonData)
        else { return nil }
        return model
    }
}

struct RequestInfo: CodableSocketData {
    let type: String
    let originator: OriginatorInfo
    
    func socketRepresentation() -> SocketData {
        ["type": type, "originator": originator.socketRepresentation()]
    }
}
