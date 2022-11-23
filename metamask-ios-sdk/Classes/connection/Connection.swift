//
//  Connection.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import OSLog
import SocketIO
import Foundation

public class Connection {

    private let keyExchange = KeyExchange()
    private let connectionClient = ConnectionClient.shared
    
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
        handleReceiveKeyExchange()
        handleRecieveMessages(on: channelId)
    }
    
    public func connect() {
        connectionClient.connect()
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
            url: connectionClient.connectionUrl)
        
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
        let channel: String = channelId
        keyExchange.updateKeyExchangeStep = { [weak self] step, publickKey in
            let keyExchangeMessage = KeyExchangeMessage(
                type: step,
            publicKey: publickKey)
            
            self?.sendMessage(keyExchangeMessage,
                              encrypt: false)
            if step == .synack {
                self?.emit(
                    ClientEvent.keysExchanged,
                    channel)
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
        
        connectionClient.onConnect = { [weak self, channelId] in
            self?.emit(
                ClientEvent.joinChannel,
                channelId, completion: {
                    DispatchQueue.main.async {
                        let url = self?.qrCodeUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        print("Deeplinking url: \(url)")
                        print("===========")
                        if let url = URL(string: url) {
                            UIApplication.shared.open(url)
                        }
                    }
                })
            
//            self?.emit(
//                ClientEvent.connected,
//                channelId, completion: { [weak self] in
//                    self?.emit(
//                        ClientEvent.createChannel,
//                        channelId)
//                })
        }
        
//        connectionClient.on(ClientEvent.channelCreated(channelId)) { _ in
//            let url = "https://metamask.app.link/connect?channelId=\(channelId)&pubkey=\(pubKey)"
//            print("Deeplink url: \(url)")
//            print("===========")
//            if let url = URL(string: url) {
//                UIApplication.shared.open(url)
//            }
//        }
        
        connectionClient.on(ClientEvent.clientsConnected(on: channelId)) { [weak self] _ in
            
            guard let self = self else { return }
            guard !self.connected else { return }
            
            
            if self.keysExchanged {
//                self.emit(
//                    ClientEvent.joinChannel,
//                    items: channelId)
            } else {
                let keyExchangeSync = self.keyExchange.keyExchangeMessage(with: .syn)
                self.sendMessage(keyExchangeSync, encrypt: false)
            }
        }
    }
    
    private func handleReceiveDisonnection(on channelId: String) {

        connectionClient.on(ClientEvent.clientDisconnected(on: channelId)) { [weak self] _ in
            Logger().log("Clients disconnected on \(channelId)")
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
        
        connectionClient.on(ClientEvent.message(on: channelId)) { [weak self] data in
//            guard
//                //let self = self,
//                let response = data.first
//            else { return }
            
            print("Receive response: \(data)")
            
//            let keysExchanged: Bool = self.keysExchanged
//            let connectionPaused: Bool = self.connectionPaused
            
            /*
            if !keysExchanged {
            
            let decrypted = keyExchange.decryptMessage()
             */
        }
    }
    
    public func sendMessage(_ message: Codable, encrypt: Bool) {
//        guard keyExchange.keysExchanged else {
//            Logger().log(level: .error, "Keys not exchanged")
//            return
//        }
        
        if encrypt {
            let encryptedMessage = try? keyExchange.encryptMessage(message)
            emit(
                ClientEvent.message,
                items: Message(
                    id: channelId,
                    message: encryptedMessage))
        } else {
//            emit(
//                ClientEvent.message,
//                items: message)
        }
    }
}

private extension Connection {
    func emit(_ event: String, _ item: String, completion: (() -> Void)? = nil) {
        connectionClient.emit(event, item, completion: completion)
    }
    
    func emit(_ event: String, items: SocketData, completion: (() -> Void)? = nil)  {
        connectionClient.emit(event, items: items, completion: completion)
    }
}

private extension Connection {
    struct OriginatorInfo: Codable {
        let title: String
        let url: String
    }
    
    struct Message<T: Codable>: Codable, SocketData {
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
