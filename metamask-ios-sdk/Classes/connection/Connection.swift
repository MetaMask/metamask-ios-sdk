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
        "https://metamask.app.link/connect?channelId=" + channelId + "&comm=socket" + "&pubkey=" + keyExchange.publicKey
    }
    
    init(channelId: String) {
        self.channelId = channelId
        
        handleReceiveMessages(on: channelId)
        handleConnection(on: channelId)
        //handleReceiveKeyExchange()
        handleDisconnection()
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
    
    private func handleReceiveKeyExchange() {
        // Whenever new key exchange event is received, handle it
        connectionClient.on(ClientEvent.keyExchange) { data in
            Logging.log("mmsdk| Key exchange: \(data)")
            
//                guard
//                    let message = data.first as? [String: AnyHashable],
//                    let keyMessage = keyExchangeMessage(from: message) else {
//                    return
//                }
//                keyExchange.handleKeyExchangeMessage?(keyMessage)
        }
    }
    
    func deeplinkToMetaMask() {
        let url = qrCodeUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        Logging.log("mmsdk| === Deeplink url: ===\n \(url)")
        if let url = URL(string: url) {
            DispatchQueue.main.async {
                Logging.log("mmsdk| \n=== Opening MetaMask ===\n")
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func handleConnection(on channelId: String) {
        
        // MARK: Connection error event
        connectionClient.on(clientEvent: .error) { data in
            Logging.log("mmsdk| >>> Client connection error: \(data) <<<")
        }
        
        // MARK: Clients connected event
        connectionClient.on(ClientEvent.clientsConnected(on: channelId)) { [weak self] data in
            guard let self = self else { return }
            Logging.log("mmsdk| >>> Clients connected: \(data) <<<")
            
            self.connected = true
            guard !self.keysExchanged else { return }
            
            Logging.log("mmsdk| >>> Initiating key exchange <<<")
            
            let keyExchangeSync = self.keyExchange.keyExchangeMessage(with: .syn)
            self.sendMessage(keyExchangeSync, encrypt: false)
            
            let keyExchangeAck = self.keyExchange.keyExchangeMessage(with: .ack)
            self.sendMessage(keyExchangeAck, encrypt: true)
        }
        
        // MARK: Socket connected event
        connectionClient.on(clientEvent: .connect) { [weak self] data in
            guard let self = self else { return }
            Logging.log("mmsdk| >>> SDK connected: \(data) <<<")
            
            self.connectionClient.emit(ClientEvent.joinChannel, channelId)
            Logging.log("mmsdk| >>> Joined channel \(channelId)")
            
            if !self.connected {
                self.deeplinkToMetaMask()
            }
        }
    }
    
    private func handleDisconnection() {
        
        // MARK: Socket disconnected event
        connectionClient.on(ClientEvent.clientDisconnected(on: channelId)) { [weak self] data in
            guard let self = self else { return }
            Logging.log("mmsdk| SDK disconnected: \(data)")
            
            if !self.connectionPaused {
                self.connected = false
                self.keysExchanged = false
                self.channelId = ""
                // Ethereum.disconnect()
            }
        }
    }
    
    private func handleReceiveMessages(on channelId: String) {
        connectionClient.on(ClientEvent.message(on: channelId)) { [weak self] data in
            guard let self = self else { return }

            Logging.log("mmsdk| Received message on channel NOW \(data.first) THEN \n \(data)")
            
            if !self.keyExchange.keysExchanged {
                guard
                    let json = data.first as? String,
                    let keyExchangeMessage = Message<KeyExchangeMessage>.keyExchangeMessage(from: json),
                    let nextKeyExchangeMessage = self.keyExchange.nextKeyExchangeMessage(keyExchangeMessage.message)
                else {
                    Logging.log("Couldn't handle data")
                    return
                }
                
                let message = Message(
                    id: channelId,
                    message: nextKeyExchangeMessage)
                Logging.log("Sending message")
                self.sendMessage(message, encrypt: true)
                self.sendOriginatorInfo()
            } else {
                Logging.log("Keys all good")
            }
        }
    }
    
    public func sendMessage<T: Codable & SocketData>(_ message: T, encrypt: Bool) {
        if encrypt && !keyExchange.keysExchanged {
            Logging.error("mmsdk| Keys not exchanged")
            return
        }
        
        if encrypt {
            if let encryptedMessage = try? keyExchange.encryptMessage(message) {
                let message = Message(
                    id: channelId,
                    message: encryptedMessage)
                connectionClient.emit(ClientEvent.message, message)
            }
        } else {
            let message = Message(
                id: channelId,
                message: message)
            connectionClient.emit(ClientEvent.message, message)
        }
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
            Logging.error(error.localizedDescription)
        }
        return nil
    }
}
