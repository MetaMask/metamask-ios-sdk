//
//  Network.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import Foundation
import SocketIO

public class Network {
    private let socket: SocketIOClient
    private var keysExchanged: Bool = false
    private var connectionPaused: Bool = false
    
    public var url: String?
    public var name: String?
    public var connected: Bool = false
    public var onClientReady: (() -> Void)?
    
    public init?(url: String) {
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
        self.socket = manager.defaultSocket
    }
    
    public func connect() {
        socket.connect()
        socket.on(clientEvent: .connect, callback: { [weak self] (sender, emitter) in
            self?.socket.emit(SocketEvent.joinChannel, with: [])
        })
    }
}

private extension Network {
    struct SocketEvent {
        static let message = "message"
        static let joinChannel = "join_channel"
        
        static func clientConnected(on channel: String)-> String {
            "clients_connected".appending("-").appending(channel)
        }
        
        static func clientDisconnected(on channel: String)-> String {
            "clients_disconnected".appending("-").appending(channel)
        }
        
        static func receiveMessage(on channel: String) -> String {
            "message".appending("-").appending(channel)
        }
    }
    
    struct Originator {
        let title: String
        let url: String
    }
    
    struct Message {
        let id: String
        var payload: AnyObject?
    }
    
    struct RequestInfo {
        
    }
}
