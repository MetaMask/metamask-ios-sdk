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
        
        handleConnection(on: channelId)
        handleReceiveKeyExchange()
        handleReceiveMessage(on: channelId)
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
    
    private func sendOriginatorInfo() async {
        let originatorInfo = OriginatorInfo(
            title: name ?? "",
            url: connectionClient.connectionUrl)
        
        let requestInfo = RequestInfo(
            type: "originator_info",
            originator: originatorInfo)
        
        await sendMessage(requestInfo, encrypt: true)
    }
    
    private func handleReceiveKeyExchange() {
        // Whenever new key exchange event is received, handle it
        Task {
            for await data in connectionClient.on(ClientEvent.keyExchange) {
                Logging.log("mmsdk| Key exchange: \(data)")
                
//                guard
//                    let message = data.first as? [String: AnyHashable],
//                    let keyMessage = keyExchangeMessage(from: message) else {
//                    return
//                }
//                keyExchange.handleKeyExchangeMessage?(keyMessage)
            }
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
        Task {
            for await error in connectionClient.on(clientEvent: .error) {
                Logging.log("mmsdk| >>> Client connection error: \(error) <<<")
            }
        }
        
        // MARK: Clients connected event
        Task {
            for await data in connectionClient.on(ClientEvent.clientsConnected(on: channelId)) {
                Logging.log("mmsdk| >>> Clients connected: \(data) <<<")
                connected = true
                
                guard !keysExchanged else { return }
                
                Logging.log("mmsdk| >>> Initiating key exchange <<<")
                
                let keyExchangeSync = keyExchange.keyExchangeMessage(with: .syn)
                await sendMessage(keyExchangeSync, encrypt: false)
            }
        }
        
        // MARK: Socket connected event
        Task {
            for await data in connectionClient.on(clientEvent: .connect) {
                Logging.log("mmsdk| >>> SDK connected: \(data) <<<")
                
                await emit(ClientEvent.joinChannel, channelId)
                Logging.log("mmsdk| >>> Joined channel \(channelId)")
                
                if !connected {
                    deeplinkToMetaMask()
                }
            }
        }
    }
    
    private func handleDisconnection() {
        
        // MARK: Socket disconnected event
        Task {
            for await error in connectionClient.on(ClientEvent.clientDisconnected(on: channelId)) {
                Logging.log("mmsdk| SDK disconnected: \(error)")
                
                if !self.connectionPaused {
                    self.connected = false
                    self.keysExchanged = false
                    self.channelId = ""
                    // Ethereum.disconnect()
                }
            }
        }
    }
    
    private func handleReceiveMessage(on channelId: String) {
        Task {
            for await data in connectionClient.on(ClientEvent.keysExchanged) {
                Logging.log("mmsdk| Keys exchanged \(data)")
                await sendOriginatorInfo()
            }
        }
        
        Task {
            for await data in connectionClient.on(ClientEvent.message(on: channelId)) {
                Logging.log("mmsdk| Received message on channel: \(data)")
                if let message = data[0] as? Message<KeyExchangeMessage> {
                    
                }
            }
        }
    }
    
    public func sendMessage<T: Codable & SocketData>(_ message: T, encrypt: Bool) async {
        if encrypt && !keyExchange.keysExchanged {
            Logging.log("mmsdk| Keys not exchanged")
            return
        }
        
        if encrypt {
            if let encryptedMessage = try? keyExchange.encryptMessage(message) {
                let message = Message(
                    id: channelId,
                    message: encryptedMessage)
                await emit(ClientEvent.message, message)
            }
        } else {
            let message = Message(
                id: channelId,
                message: message)
            await emit(ClientEvent.message, message)
        }
    }
}

private extension Connection {
    func emit(_ event: String, _ item: SocketData) async {
        await connectionClient.emit(event, item)
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
