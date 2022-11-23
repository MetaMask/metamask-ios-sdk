//
//  NetworkClient.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/07.
//

import OSLog
import Foundation
import SocketIO

enum ClientEvent { }

extension ClientEvent {
    static var connected: String {
        "connection"
    }
    
    static var disconnected: String {
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
    
    static func channelCreated(_ channel: String)-> String {
        "channel_created".appending("-").appending(channel)
    }
    
    static func clientsConnected(on channel: String)-> String {
        "clients_connected".appending("-").appending(channel)
    }
    
    static func clientDisconnected(on channel: String)-> String {
        "clients_disconnected".appending("-").appending(channel)
    }
    
    static func message(on channelId: String) -> String {
        "message".appending("-").appending(channelId)
    }
}

class ConnectionClient {
    static let shared = ConnectionClient()
    
    let connectionUrl = "https://socket.codefi.network"
    let socket: SocketIOClient
    private var socketManager: SocketManager
    var onConnect: (() -> Void)?
    
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
    
    func connect() {
        socket.connect()
        socket.on(clientEvent: .error) { data, _ in
            print(">>>>>>")
            print("Error: \(data)")
            print("<<<<<<")
        }

        socket.on(clientEvent: .connect) { [weak self] data, _ in
            print(">>>>>>")
            print("Client connected!: \(data)")
            print("<<<<<<")
            self?.onConnect?()
        }
    }
    
    func disconnect() {
        socket.disconnect()
    }

    func on(_ event: String, callback: @escaping (Any...) -> Void) {
        socket.on(event) { data, _ in
            callback(data)
        }
    }
    
    func emit(_ event: String, _ item: String, completion: (() -> Void)? = nil) {
        socket.emit(event, item, completion: completion)
    }
    
    func emit(_ event: String, items: SocketData..., completion: (() -> Void)? = nil) {
        socket.emit(event, items, completion: completion)
    }
}
