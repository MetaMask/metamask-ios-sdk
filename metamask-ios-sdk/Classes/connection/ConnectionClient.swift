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
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    func on(clientEvent: SocketClientEvent) async -> [Any] {
        await withCheckedContinuation { continuation in
            // prevent "Swift task continuation misuse" fatal error from resuming continuation more than once
            var promise: CheckedContinuation<[Any], Never>? = continuation
            socket.on(clientEvent: clientEvent) { data, _ in
                promise?.resume(returning: data)
                promise = nil
            }
        }
    }

    func on(_ event: String) async -> [Any] {
        await withCheckedContinuation { continuation in
            var promise: CheckedContinuation<[Any], Never>? = continuation
            socket.on(event) { data, _ in
                promise?.resume(returning: data)
                promise = nil
            }
        }
    }
    
    func emit(_ event: String, _ item: SocketData) async {
        await withCheckedContinuation { continuation in
            var promise: CheckedContinuation<Void, Never>? = continuation
            socket.emit(event, item, completion: {
                promise?.resume()
                promise = nil
            })
        }
    }
}
