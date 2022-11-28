//
//  NetworkClient.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/07.
//

import OSLog
import Foundation
import SocketIO

struct ClientEvent {
    static var connected: String {
        "connection"
    }
    
    static var disconnect: String {
        "disconnect"
    }
    
    static var message: String {
        "message"
    }
    
    static var keyExchange: String {
        "key_exchange"
    }
    
    static var keysExchanged: String {
        "keys_exchanged"
    }
    
    static var joinChannel: String {
        "join_channel"
    }
    
    static var createChannel: String {
        "create_channel"
    }
    
    static func waitingToJoin(_ channel: String) -> String {
        "clients_waiting_to_join".appending("-").appending(channel)
    }
    
    static func channelCreated(_ channel: String) -> String {
        "channel_created".appending("-").appending(channel)
    }
    
    static func clientsConnected(on channel: String) -> String {
        "clients_connected".appending("-").appending(channel)
    }
    
    static func clientDisconnected(on channel: String) -> String {
        "clients_disconnected".appending("-").appending(channel)
    }
    
    static func message(on channelId: String) -> String {
        "message".appending("-").appending(channelId)
    }
}

class ConnectionClient {
    static let shared = ConnectionClient()
    
    let connectionUrl = "https://metamask-sdk-socket.metafi.codefi.network/"
    let socket: SocketIOClient
    private let socketManager: SocketManager
    
    private init() {
        let url = URL(string: connectionUrl)!
        let options: SocketIOClientOption = .extraHeaders(
            [
                "User-Agent": "SocketIOClient"
            ]
        )
        
        socketManager = SocketManager(
            socketURL: url,
            config: [
                .log(true),
                options
            ])
        socket = socketManager.defaultSocket
        
    }
}

// MARK: Session
extension ConnectionClient {
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
}

// MARK: Events
extension ConnectionClient {
    func on(clientEvent: SocketClientEvent, completion: @escaping ([Any]) -> Void) {
        socket.on(clientEvent: clientEvent, callback: { data, _ in
            completion(data)
        })
    }
    
    func on(_ event: String, completion: @escaping ([Any]) -> Void) {
        socket.on(event, callback: { data, _ in
            completion(data)
        })
    }
    
    func emit(_ event: String, _ item: SocketData) {
        socket.emit(event, item)
    }
}
