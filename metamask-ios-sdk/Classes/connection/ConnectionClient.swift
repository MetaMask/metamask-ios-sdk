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
    
    // older url: "https://socket.codefi.network"
    let connectionUrl = "http://127.0.0.1:4000"//"https://metamask-sdk-socket.metafi.codefi.network/"
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
    // Connection event callback
    func on(clientEvent: SocketClientEvent) -> AsyncStream<any Sequence> {
        AsyncStream { continuation in
            socket.on(clientEvent: clientEvent) { data, _ in
                continuation.yield(data)
            }
        }
    }
    
    // Custom event callback
    func on(_ event: String) -> AsyncStream<any Sequence> {
        AsyncStream { continuation in
            socket.on(event) { data, _ in
                continuation.yield(data)
            }
        }
    }
    
    // Custom events sending
    func emit(_ event: String, _ item: SocketData) async {
        await withCheckedContinuation { continuation in
            socket.emit(event, item, completion: {
                continuation.resume()
            })
        }
    }
}
