//
//  NetworkClient.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/07.
//

import OSLog
import Foundation
import SocketIO

enum ClientEvent {
    case connect
    case disconnect
}

extension ClientEvent {
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
    
    static func clientConnected(on channel: String)-> String {
        "clients_connected".appending("-").appending(channel)
    }
    
    static func clientDisconnected(on channel: String)-> String {
        "clients_disconnected".appending("-").appending(channel)
    }
    
    static func receive(on channelId: String) -> String {
        "message".appending("-").appending(channelId)
    }
}

class ConnectionClient {
    private var socket: SocketIOClient?
    
    public let networkUrl: String
    
    init(networkUrl: String = "https://socket.codefi.network") {
        self.networkUrl = networkUrl
        self.socket = makeSocketClient(url: networkUrl)
    }
    
    func connect() {
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    private func makeSocketClient(url: String) -> SocketIOClient? {
        guard let url = URL(string: url) else { return nil }
        let options: SocketIOClientOption = .extraHeaders(
            [
                "User-Agent": "SocketIOClient"
            ]
        )
        let manager = SocketManager(
            socketURL: url,
            config: [
                .log(true),
                options
            ]
        )
        return manager.defaultSocket
    }
    
    func on(_ event: String, callback: @escaping (Any...) -> Void) {
        socket?.on(event) { data, _ in
            callback(data)
        }
    }
    
    func on(clientEvent: ClientEvent, callback: @escaping (Any...) -> Void) {
        let socketEvent: SocketClientEvent
        switch clientEvent {
        case .connect:
            socketEvent = .connect
        case .disconnect:
            socketEvent = .disconnect
        }
        socket?.on(clientEvent: socketEvent) { data, _ in
            callback(data)
        }
    }
    
    func emit(_ event: String, with items: Any...) {
        socket?.emit(event, with: items)
    }
}
