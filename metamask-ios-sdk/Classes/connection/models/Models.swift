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
    
    func socketRepresentation() -> CodableSocketData {
        [
            "id": id,
            "message": try? message.socketRepresentation()
        ]
    }
}

struct RequestInfo: CodableSocketData {
    let type: String
    let originator: OriginatorInfo
    
    func socketRepresentation() -> CodableSocketData {
        ["type": type, "originator": originator]
    }
}
