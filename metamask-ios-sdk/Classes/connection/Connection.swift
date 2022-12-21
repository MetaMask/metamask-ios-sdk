//
//  Connection.swift
//

import OSLog
import SocketIO
import Foundation
import Combine

class Connection {

    private var keyExchange = KeyExchange()
    private let connectionClient = ConnectionClient.shared
    
    private var connectionPaused: Bool = false
    private var channelId: String!
    
    var url: String?
    var name: String?
    
    var connected: Bool = false
    var onClientsReady: (() -> Void)?
    var onClientsDisconnected: (() -> Void)?
    
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
            Logging.error("mmsdk| Client connection error: \(data)")
        }
        
        // MARK: Clients connected event
        connectionClient.on(ClientEvent.clientsConnected(on: channelId)) { [weak self] data in
            guard let self = self else { return }
            Logging.log("mmsdk| Clients connected: \(data)")
            
            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Clients Connected"])
            
            self.connected = true
            
            let keyExchangeSync = self.keyExchange.message(type: .syn)
            self.sendMessage(keyExchangeSync, encrypt: false)
        }
        
        // MARK: Socket connected event
        connectionClient.on(clientEvent: .connect) { [weak self] data in
            guard let self = self else { return }
            
            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Connected to Socket"])
            
            Logging.log("mmsdk| SDK connected: \(data)")
            
            self.connectionClient.emit(ClientEvent.joinChannel, channelId)
            
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
            
            // for debug purposes only
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
        
        do {
            let json: [String: Any] = try JSONSerialization.jsonObject(with: Data(decryptedText.utf8), options: []) as? [String: Any] ?? [:]
            
            if json["type"] as? String == "pause" {
                Logging.log("mmsdk| Connection has been paused")
                connectionPaused = true
            } else if json["type"] as? String == "ready" {
                Logging.log("mmsdk| Connection is ready")
                connectionPaused = false
                onClientsReady?()
            } else if json["type"] as? String == "wallet_info" {
                Logging.log("mmsdk| Received wallet info")
                connected = true
                onClientsReady?()
                connectionPaused = false
            } else if let data = json["data"] as? [String: Any] {
                if let id = data["id"] as? String {
                    Ethereum.shared.receiveResponse(
                        id: id,
                        data: data)
                } else {
                    Ethereum.shared.receiveEvent(data)
                }
            }
        } catch {
            Logging.error(error)
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
            return
        }
        
        if encrypt {
            do {
                let encryptedMessage: String = try keyExchange.encryptMessage(message)
                let message: Message<String> = Message(
                    id: channelId,
                    message: encryptedMessage)
                
                if connectionPaused {
                    Logging.log("mmsdk| Will send once wallet is open again")
                    onClientsReady = { [weak self] in
                        Logging.log("mmsdk| Sending now")
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
