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

    private var keyExchange = KeyExchange()
    private let connectionClient = ConnectionClient.shared
    
    private var connectionPaused: Bool = false
    private var channelId: String!
    
    public var name: String {
        "Metamask iOS SDK"
    }
    public var connected: Bool = false
    public var onClientReady: (() -> Void)?
    
    var qrCodeUrl: String {
        "https://metamask.app.link/connect?channelId=" + channelId + "&comm=socket" + "&pubkey=" + keyExchange.pubkey
    }
    
    init(channelId: String) {
        self.channelId = channelId
        
        handleReceiveMessages(on: channelId)
        handleConnection(on: channelId)
        handleDisconnection()
    }
    
    public func connect(on channelId: String? = nil) {
        if let channel = channelId {
            keyExchange = KeyExchange()
            handleReceiveMessages(on: channel)
            handleConnection(on: channel)
        }
        connectionClient.connect()
    }
    
    public func disconnect() {
        channelId = ""
        connected = false
        keyExchange.keysExchanged = false
        connectionClient.disconnect()
    }
}

// MARK: Event handling
private extension Connection {
    func handleConnection(on channelId: String) {
        
        // MARK: Connection error event
        connectionClient.on(clientEvent: .error) { data in
            Logging.log("mmsdk| Client connection error: \(data)")
        }
        
        // MARK: Clients connected event
        connectionClient.on(ClientEvent.clientsConnected(on: channelId)) { [weak self] data in
            guard let self = self else { return }
            Logging.log("mmsdk| Clients connected: \(data)")
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Clients Connected"])
            
            self.connected = true
            
            Logging.log("mmsdk| Initiating key exchange")
            
            let keyExchangeSync = self.keyExchange.message(type: .syn)
            self.sendMessage(keyExchangeSync, encrypt: false)
        }
        
        // MARK: Socket connected event
        connectionClient.on(clientEvent: .connect) { [weak self] data in
            guard let self = self else { return }
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Connected to Socket"])
            Logging.log("mmsdk| SDK connected: \(data)")
            
            self.connectionClient.emit(ClientEvent.joinChannel, channelId)

            NotificationCenter.default.post(
                name: NSNotification.Name("channel"),
                object: nil,
                userInfo: ["value": channelId])
            Logging.log("mmsdk| Joined channel: \(channelId)")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("deeplink"),
                object: nil,
                userInfo: ["value": "\(self.qrCodeUrl)"])
            
            if !self.connected {
                //self.deeplinkToMetaMask()
            }
        }
    }
    
    func handleReceiveMessages(on channelId: String) {
        // MARK: New message received
        connectionClient.on(ClientEvent.message(on: channelId)) { [weak self] data in
            guard
                let self = self,
                let message = data.first as? [String: Any]
            else { return }
            NotificationCenter.default.post(
                name: NSNotification.Name("event"),
                object: nil,
                userInfo: ["value": "Received message: \(message)"])

            Logging.log("mmsdk| Received message: \(message)")

            if !self.keyExchange.keysExchanged {
                self.handleReceiveKeyExchange(message)
            } else {
                // Decrypt message
                self.handleMessage(message)
            }
        }
    }
    
    func handleDisconnection() {
        // MARK: Socket disconnected event
        connectionClient.on(ClientEvent.clientDisconnected(on: channelId)) { [weak self] data in
            guard let self = self else { return }
            Logging.log("mmsdk| SDK disconnected: \(data)")
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Clients Disconnected"])
            
            if !self.connectionPaused {
                self.connected = false
                self.keyExchange.keysExchanged = false
                self.channelId = ""
                // Ethereum.disconnect()
            }
        }
    }
}

// MARK: Message handling
private extension Connection {
    func handleReceiveKeyExchange(_ message: [String: Any]) {
        guard let keyExchangeMessage = Message<KeyExchangeMessage>.message(from: message) else {
            Logging.log("mmsdk| Couldn't construct key exchange from data")
            return
        }
        
        guard let nextKeyExchangeMessage = keyExchange.nextMessage(keyExchangeMessage.message) else {
            return
        }

        sendMessage(nextKeyExchangeMessage, encrypt: false)
        if keyExchange.keysExchanged {
            sendOriginatorInfo()
        }
    }
    
    func handleMessage(_ message: [String: Any]) {
        if connectionPaused {
            if
                let type = message["type"] as? String,
                let keyExchangeType = KeyExchangeType(rawValue: type),
                keyExchangeType == .start {
                keyExchange.keysExchanged = false
                connectionPaused = false
                connected = false
                
                let keyExchangeSync = keyExchange.message(type: .syn)
                sendMessage(keyExchangeSync, encrypt: false)
                return
            }
        }
        
        guard let message = Message<String>.message(from: message) else { return }
        let decryptedText: String
        
        do {
            decryptedText = try keyExchange.decryptMessage(message.message)
        } catch {
            Logging.error(error)
            return
        }
        
        let json: [String: Any]
        
        do {
            json = try JSONSerialization.jsonObject(with: Data(decryptedText.utf8), options: []) as? [String: Any] ?? [:]
            NotificationCenter.default.post(
                name: NSNotification.Name("event"),
                object: nil,
                userInfo: ["value": "Received message: \(json)"])
        } catch {
            Logging.error(error)
            return
        }
        
        if json["type"] as? String == "pause" {
            Logging.log("mmsdk| Connection has been paused")
            connectionPaused = true
            return
        } else if json["type"] as? String == "ready" {
            Logging.log("mmsdk| Connection is ready!")
            connectionPaused = false
            onClientReady?()
        }
        
        if !connected {
            if json["type"] as? String == "wallet_info" {
                Logging.log("mmsdk| Got wallet info!")
                connected = true
                onClientReady?()
                connectionPaused = false
                return
            }
        }
        
        if let data = json["data"] as? [String: Any] {
            if let id = data["id"] as? String {
                Logging.log("mmsdk| Received ethereum request with id: \(id)")
                //Ethereum.receiveRequest(id, data)
            } else {
                Logging.log("mmsdk| Received ethereum event: \(data)")
                //Ethereum.receiveEvent(data)
            }
        }
    }
}

// MARK: Helper methods
public extension Connection {
    func deeplinkToMetaMask() {
        guard
            let urlString = qrCodeUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString)
        else { return }
        
        Logging.log("mmsdk| Deeplinking to MetaMask. \nURL: \(urlString)")
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: Message sending
private extension Connection {
    func sendOriginatorInfo() {
        let originatorInfo = OriginatorInfo(
            title: name,
            url: connectionClient.connectionUrl)
        
        let requestInfo = RequestInfo(
            type: "originator_info",
            originator: originatorInfo)
        
        sendMessage(requestInfo, encrypt: true)
    }
    
    func sendMessage<T: Codable & SocketData>(_ message: T, encrypt: Bool) {
        if encrypt && !keyExchange.keysExchanged {
            Logging.error("mmsdk| Keys not exchanged")
            return
        }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("event"),
            object: nil,
            userInfo: ["value": "Sending message: \(message)"])
        
        if encrypt {
            do {
                let encryptedMessage = try keyExchange.encryptMessage(message)
                let message = Message(
                    id: channelId,
                    message: encryptedMessage)
                
                connectionClient.emit(ClientEvent.message, message)
            } catch {
                Logging.error(error)
            }
        } else {
            let message = Message(
                id: channelId,
                message: message)
            
            connectionClient.emit(ClientEvent.message, message)
        }
    }
}
