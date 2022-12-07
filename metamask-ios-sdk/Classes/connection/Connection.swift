//
//  Connection.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import OSLog
import SocketIO
import Foundation

class Connection {

    private var keyExchange = KeyExchange()
    private let connectionClient = ConnectionClient.shared
    
    private var connectionPaused: Bool = false
    private var channelId: String!
    
    var url: String?
    var name: String?
    
    var connected: Bool = false
    var onClientsReady: (() -> Void)?
    
    var deeplinkUrl: String {
        "https://metamask.app.link/connect?channelId=" + channelId + "&comm=socket" + "&pubkey=" + keyExchange.pubkey
    }
    
    init(channelId: String) {
        self.channelId = channelId
        
        handleReceiveMessages(on: channelId)
        handleConnection(on: channelId)
        handleDisconnection()
    }
    
    func connect(on channelId: String? = nil) {
        if let channel = channelId {
            keyExchange = KeyExchange()
            handleReceiveMessages(on: channel)
            handleConnection(on: channel)
        }
        connectionClient.connect()
    }
    
    func disconnect() {
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
            
            if !self.connected {
                self.deeplinkToMetaMask()
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
                Logging.log("mmsdk| About to decrypt message: \(message)")
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
                Ethereum.shared.disconnect()
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
    
    func handlePausedConnection() {
        
    }
    
    func handleMessage(_ message: [String: Any]) {
        if connectionPaused {
            if
                let message = message["message"] as? [String: Any],
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
                userInfo: ["value": "Received decrypted message: \(json)"])
            
            Logging.log("mmsdk| Received decrypted message: \(json)")
        } catch {
            Logging.error(error)
            return
        }
        
        if json["type"] as? String == "pause" {
            Logging.log("mmsdk| Connection has been paused")
            connectionPaused = true
        } else if json["type"] as? String == "ready" {
            Logging.log("mmsdk| Connection is ready!")
            connectionPaused = false
            onClientsReady?()
        } else if json["type"] as? String == "wallet_info" {
            Logging.log("mmsdk| Got wallet info!")
            connected = true
            onClientsReady?()
            connectionPaused = false
        } else if let data = json["data"] as? [String: Any] {
            if let id = data["id"] as? String {
                Ethereum.shared.receiveResponse(
                    id: id,
                    data: data)
            } else {
                Logging.log("mmsdk| Received ethereum event: \(data)")
                Ethereum.shared.receiveEvent(data)
            }
        }
    }
}

// MARK: Helper methods
extension Connection {
    func deeplinkToMetaMask() {
        guard
            let urlString = deeplinkUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString)
        else { return }
        
        Logging.log("mmsdk| Deeplinking to MetaMask. \nURL: \(urlString)")
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: Message sending
extension Connection {
    func sendOriginatorInfo() {
        let originatorInfo = OriginatorInfo(
            title: name,
            url: url)
        
        let requestInfo = RequestInfo(
            type: "originator_info",
            originator: originatorInfo)
        
        sendMessage(requestInfo, encrypt: true)
    }
    
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool) {
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
                let encryptedMessage: String = try keyExchange.encryptMessage(message)
                let message: Message<String> = Message(
                    id: channelId,
                    message: encryptedMessage)
                
                if connectionPaused {
                    Logging.log("Will send once wallet is open again")
                    onClientsReady = { [weak self] in
                        Logging.log("Sending now")
                        self?.connectionClient.emit(ClientEvent.message, message)
                    }
                } else {
                    connectionClient.emit(ClientEvent.message, message)
                }
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
