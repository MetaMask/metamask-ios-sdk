//
//  Network.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import Foundation

import OSLog

public class Network {

    private var keyExchange: KeyExchange!
    private var networkClient: NetworkClient!
    
    private var keysExchanged: Bool = false
    private var connectionPaused: Bool = false
    private var channelId = UUID().uuidString
    
    public var name: String?
    public var connected: Bool = false
    public var onClientReady: (() -> Void)?
    
    public func connect() {
        keyExchange = KeyExchange()
        networkClient = NetworkClient()
        
        let metaMaskUrl = "https://metamask.app.link/connect?channelId=" + channelId + "&pubkey=" + keyExchange.publicKey
        Logger().log("\(metaMaskUrl)")
        
        handleReceiveKeyExchange()
        handleRecieveMessages(on: channelId)
        networkClient.connect()
    }
}

extension Network {
    
    private func sendOriginatorInfo() {
        let originatorInfo = OriginatorInfo(
            title: name ?? "",
            url: networkClient.networkUrl)
        
        let requestInfo = RequestInfo(
            type: "originator_info",
            originator: originatorInfo)
        
        sendMessage(requestInfo, encrypt: true)
    }
    
    public func handleRecieveMessages(on channelId: String) {
        handleReceiveMessage(on: channelId)
        handleReceiveConnection(on: channelId)
        handleReceiveDisonnection(on: channelId)
    }
    
    private func handleReceiveKeyExchange() {
        networkClient.on(ClientEvent.keyExchange) { [weak self] data in
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
        networkClient.on(clientEvent: .connect) { [weak self] _ in
            Logger().log("Clients connected")
            guard let self = self else { return }
            
            if self.keysExchanged {
                self.networkClient.emit(
                    ClientEvent.joinChannel,
                    with: [])
            } else {
                let keyExchangeSync = self.keyExchange.keyExchangeMessage(with: .syn)
                self.sendMessage(keyExchangeSync, encrypt: false)
            }
        }
    }
    
    private func handleReceiveDisonnection(on channelId: String) {
        networkClient.on(clientEvent: .disconnect) { [weak self] _ in
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
        networkClient.on(ClientEvent.receive(on: channelId)) { [weak self] data in
            guard
                let self = self,
                let response = data.first as? [String: AnyHashable]
            else { return }
            
            let keysExchanged: Bool = self.keysExchanged
            let connectionPaused: Bool = self.connectionPaused
            
            /*
            if !keysExchanged {
                
                switch message.type {
                case .start:
                    
                    
                }
                if message.type == .synack {
                    self.keyExchange.theirPublicKey = message.publicKey
                    let keyExchangeAck = self.keyExchange.keyExchangeMessage(with: .ack)
                    self.sendMessage(keyExchangeAck, encrypt: false)
                    self.keysExchanged = true
                    self.sendOriginatorInfo()
                } else {
                    
                }
            } else {
                if message.type == .start {
                    self.keysExchanged = true
                    self.connectionPaused = false
                    self.connected = false
                    let keyExchangeSync = self.keyExchange.keyExchangeMessage(with: .syn)
                    self.sendMessage(keyExchangeSync, encrypt: false)
                    return
                }
            }
            
            
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
        
        networkClient.emit(
            ClientEvent.message,
            with: [
                Message(
                    id: channelId,
                    message: encryptedMessage)
            ])
    }
}

private extension Network {
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

private extension Network {
    func keyExchangeMessage(from dictionary: [String: AnyHashable]) -> KeyExchangeMessage? {
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
