//
//  Network.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import Foundation
import SocketIO
import OSLog

public class Network {
    private var socket: SocketIOClient?
    private let keyExchange = KeyExchange()
    private var keysExchanged: Bool = false
    private var connectionPaused: Bool = false
    
    public var socketUrl: String = "https://socket.codefi.network" {
        didSet {
            self.socket = makeSocketClient(url: socketUrl)
        }
    }
    
    public var name: String?
    public var connected: Bool = false
    public var onClientReady: (() -> Void)?
    
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
    
    public func connect() {
        let keyExchange = KeyExchange()
        let metaMaskUrl = "https://metamask.app.link/connect?channelId=" + UUID().uuidString + "&pubkey=" + keyExchange.publicKey
        Logger().log("\(metaMaskUrl)")
        
        socket = makeSocketClient(url: socketUrl)
        socket?.on(clientEvent: .connect) { [weak self] _,_ in
            Logger().log("Socket connected")
            self?.recieveMessages(on: "")
            self?.socket?.emit(SocketEvent.joinChannel, with: [])
        }
        socket?.connect()
    }
}

extension Network {
    
    private func sendOriginatorInfo() {
        let originatorInfo = OriginatorInfo(
            title: name ?? "",
            url: socketUrl)
        
        let requestInfo = RequestInfo(
            type: "originator_info",
            originator: originatorInfo)
        
        sendMessage(requestInfo, encrypt: true)
    }
    
    public func recieveMessages(on channelId: String) {
        handleReceiveMessage(on: channelId)
        handleReceiveConnection(on: channelId)
        handleReceiveDisonnection(on: channelId)
    }
    
    private func handleReceiveConnection(on channelId: String) {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            Logger().log("Clients connected")
            guard let self = self else { return }
            
            if !self.keysExchanged {
                let keyExchangeSync = self.keyExchange.keyExchangeMessage(with: .handshakeSynchronise)
                self.sendMessage(keyExchangeSync, encrypt: false)
            }
        }
    }
    
    private func handleReceiveDisonnection(on channelId: String) {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            Logger().log("Clients disconnected")
            guard let self = self else { return }
            
            if !self.connectionPaused {
                self.connected = false
                self.keysExchanged = false
                // self.id = nil
                // Ethereum.disconnect()
            }
        }
    }
    
    private func handleReceiveMessage(on channelId: String) {
        socket?.on(SocketEvent.receive(on: channelId)) { [weak self] data, ack in
            guard
                let self = self,
                let data = data.first,
                let receivedMessage = data as? Message
            else { return }
            
            let keysExchanged: Bool = self.keysExchanged
            let connectionPaused: Bool = self.connectionPaused
            
            if !keysExchanged {
                let message = receivedMessage.message
                
                if message.type == .handshakeSynchroniseAcknowledgement {
                    self.keyExchange.theirPublicKey = message.publicKey
                    let keyExchangeAck = self.keyExchange.keyExchangeMessage(with: .handshakeAcknowledge)
                    self.sendMessage(keyExchangeAck, encrypt: false)
                    self.keysExchanged = true
                    self.sendOriginatorInfo()
                }
            } else {
                if connectionPaused && receivedMessage.message.type == .handshakeStart {
                    self.keysExchanged = true
                    self.connectionPaused = false
                    self.connected = true
                    let keyExchangeSync = self.keyExchange.keyExchangeMessage(with: .handshakeSynchronise)
                    self.sendMessage(keyExchangeSync, encrypt: false)
                    return
                }
            }
            
            // more logic here
        }
    }
    
    public func sendMessage(_ message: Codable, encrypt: Bool) {
//        let message = encrypt
//            ? keyExchange.encryptMessage(message)
//            : message
//        Message(id: id)
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
        
        static func receive(on channelId: String) -> String {
            "message".appending("-").appending(channelId)
        }
    }
    
    struct OriginatorInfo: Codable {
        let title: String
        let url: String
    }
    
    struct Message: Codable {
        let id: String
        var message: KeyExchangeMessage
    }
    
    struct RequestInfo: Codable {
        let type: String
        let originator: OriginatorInfo
    }
}
