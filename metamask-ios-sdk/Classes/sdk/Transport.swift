//
//  Transport.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import OSLog
import Foundation

class Transport {
    
    private var connection = Connection(channelId: UUID().uuidString.lowercased())
    
    var url: String? {
        didSet {
            connection.url = url
        }
    }
    
    var name: String? {
        didSet {
            connection.name = name
        }
    }
    
    var onClientsReady: (() -> Void)? {
        didSet {
            connection.onClientsReady = onClientsReady
        }
    }
    
    var isConnected: Bool {
        connection.connected
    }
    
    func connect() {
        connection.connect()
    }
    
    func disconnect() {
        connection.disconnect()
    }
    
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool) {
        connection.sendMessage(message, encrypt: encrypt)
    }
}
