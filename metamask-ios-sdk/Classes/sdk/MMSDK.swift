//
//  MMSDK.swift
//

import OSLog
import Foundation
import Combine

class MMSDK {
    
    private var connection = Connection(channelId: UUID().uuidString.lowercased())
    
    var dappUrl: String? {
        didSet {
            connection.url = dappUrl
        }
    }
    
    var dappName: String? {
        didSet {
            connection.name = dappName
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
