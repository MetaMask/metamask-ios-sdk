//
//  Connection.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import OSLog
import Foundation

public class Connection {

    private let keyExchange: KeyExchange
    private let connectionClient: ConnectionClient
    
    private var keysExchanged: Bool = false
    private var connectionPaused: Bool = false
    private var channelId: String!
    
    public var name: String?
    public var connected: Bool = false
    public var onClientReady: (() -> Void)?
    
    var qrCodeUrl: String {
        "https://metamask.app.link/connect?channelId=" + channelId + "&pubkey=" + keyExchange.publicKey
    }
    
    init(channelId: String) {
        self.channelId = channelId
        keyExchange = KeyExchange()
        connectionClient = ConnectionClient()
        handleReceiveKeyExchange()
        handleRecieveMessages(on: channelId)
    }
    
    public func connect(on channelID: String? = nil) {
        if let channelId = channelID {
            self.channelId = channelId
            handleRecieveMessages(on: channelId)
        }
        connectionClient.connect()
        
        let channel = channelID ?? ""
        connectionClient.on(ClientEvent.clientConnected(on: channelId)) { _ in
            print("Clients connected on \(channel)!")
        }
        
        connectionClient.on(ClientEvent.clientDisconnected(on: channelId)) { _ in
            print("Clients disconnected on \(channel)!")
        }
        
        // Start key exchange negotiation
        sendMessage(KeyExchangeMessage(type: .syn), encrypt: false)
    }
    
    public func disconnect() {
        channelId = ""
        connected = false
        keysExchanged = false
        connectionClient.disconnect()
    }
    
    public func on(_ event: String, callback: @escaping (Any...) -> Void) {
        connectionClient.on(event, callback: callback)
    }
}

extension Connection {
    
    private func sendOriginatorInfo() {
        let originatorInfo = OriginatorInfo(
            title: name ?? "",
            url: connectionClient.networkUrl)
        
        let requestInfo = RequestInfo(
            type: "originator_info",
            originator: originatorInfo)
        
        sendMessage(requestInfo, encrypt: true)
    }
    
    private func handleRecieveMessages(on channelId: String) {
        handleReceiveMessage(on: channelId)
        handleReceiveConnection(on: channelId)
        handleReceiveDisonnection(on: channelId)
    }
    
    private func handleReceiveKeyExchange() {
        // Whenever key exchange step changes, send new step info
        keyExchange.updateKeyExchangeStep = { [weak self] step, publickKey in
            let keyExchangeMessage = KeyExchangeMessage(
                type: step,
            publicKey: publickKey)
            
            self?.sendMessage(keyExchangeMessage,
                              encrypt: false)
            if step == .synack {
                self?.connectionClient.emit(ClientEvent.keysExchanged, with: [])
            }
        }
        
        // Whenever new key exchange event is received, handle it
        connectionClient.on(ClientEvent.keyExchange) { [weak self] data in
            guard
                let self = self,
                let message = data.first as? [String: AnyHashable],
                let keyMessage = self.keyExchangeMessage(from: message) else {
                return
            }
            self.keyExchange.handleKeyExchangeMessage?(keyMessage)
        }
    }
    
    private func handleReceiveConnection(on channelId: String) {
        connectionClient.on(clientEvent: .connect) { [weak self] _ in
            Logger().log("Clients connected")
            guard let self = self else { return }
            
            if self.keysExchanged {
                self.connectionClient.emit(
                    ClientEvent.joinChannel,
                    with: [])
            } else {
                let keyExchangeSync = self.keyExchange.keyExchangeMessage(with: .syn)
                self.sendMessage(keyExchangeSync, encrypt: false)
            }
        }
    }
    
    private func handleReceiveDisonnection(on channelId: String) {
        connectionClient.on(clientEvent: .disconnect) { [weak self] _ in
            Logger().log("Clients disconnected")
            guard let self = self else { return }
            
            if !self.connectionPaused {
                self.connected = false
                self.keysExchanged = false
                self.channelId = ""
                // Ethereum.disconnect()
            }
        }
    }
    
    private func handleReceiveMessage(on channelId: String) {
        connectionClient.on(ClientEvent.keysExchanged) { [weak self] _ in
            self?.sendOriginatorInfo()
        }
        
        connectionClient.on(ClientEvent.receive(on: channelId)) { [weak self] data in
            guard
                let self = self,
                let response = data.first as? [String: AnyHashable]
            else { return }
            
            let keysExchanged: Bool = self.keysExchanged
            let connectionPaused: Bool = self.connectionPaused
            
            /*
            if !keysExchanged {
            
            let decrypted = keyExchange.decryptMessage()
             */
        }
    }
    
    public func sendMessage(_ message: Codable, encrypt: Bool) {
        guard keyExchange.keysExchanged else {
            Logger().log(level: .error, "Keys not exchanged")
            return
        }
        
        let encryptedMessage = try? keyExchange.encryptMessage(message)
        
        connectionClient.emit(
            ClientEvent.message,
            with: [
                Message(
                    id: channelId,
                    message: encryptedMessage)
            ])
    }
}

private extension Connection {
    struct OriginatorInfo: Codable {
        let title: String
        let url: String
    }
    
    struct Message<T: Codable>: Codable {
        //let type: KeyExchangeStep
        var id: String
        var message: T?
    }
    
    struct RequestInfo: Codable {
        let type: String
        let originator: OriginatorInfo
    }
}

private extension Connection {
    private func keyExchangeMessage(from dictionary: [String: AnyHashable]) -> KeyExchangeMessage? {
        do {
            let json = try JSONSerialization.data(withJSONObject: dictionary)
            let decoder = JSONDecoder()
            let keyExchange = try decoder.decode(KeyExchangeMessage.self, from: json)
            return keyExchange
        } catch {
            Logger().log(
                level: .error,
                "\(error.localizedDescription)")
        }
        return nil
    }
}
