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
    
//    public func on(_ event: String, callback: @escaping (Any...) -> Void) {
//        connectionClient.on(event, callback: callback)
//    }
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
    
    private func handleRecieveMessages(on channelId: String) {
        handleReceiveMessage(on: channelId)
        handleReceiveConnection(on: channelId)
        handleReceiveDisonnection(on: channelId)
    }
    
    private func handleReceiveKeyExchange() {
        // Whenever key exchange step changes, send new step info
//        let channel: String = channelId
//        keyExchange.updateKeyExchangeStep = { [weak self] step, publickKey in
//            let keyExchangeMessage = KeyExchangeMessage(
//                type: step,
//            publicKey: publickKey)
//
//            self?.sendMessage(keyExchangeMessage,
//                              encrypt: false)
//            if step == .synack {
//                self?.emit(
//                    ClientEvent.keysExchanged,
//                    channel)
//            }
//        }
        
        // Whenever new key exchange event is received, handle it
        Task {
            let data = await connectionClient.on(ClientEvent.keyExchange)
            Logging.log("mmsdk| Key exchange: \(data)")
            
            guard
                let message = data.first as? [String: AnyHashable],
                let keyMessage = keyExchangeMessage(from: message) else {
                return
            }
            keyExchange.handleKeyExchangeMessage?(keyMessage)
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
    
    struct JoinInfo: Codable, SocketData {
        let name: String
        let reason: String
        
        func socketRepresentation() -> SocketData {
            return ["name": name, "reason": reason]
        }
    }
    
    private func handleReceiveConnection(on channelId: String) {
        Task {
            let error = await connectionClient.on(clientEvent: .error)
            Logging.log("mmsdk| >>> Client connection error: \(error) <<<")
        }
        
        Task {
            let data = await connectionClient.on(clientEvent: .connect)
            Logging.log("mmsdk| >>> Client connected: \(data) <<<")
            
            await emit(ClientEvent.joinChannel, JoinInfo(name: "Peter John", reason: "Social chat"))
            Logging.log("mmsdk| >>> Joined channel \(channelId)")
            
            //deeplinkToMetaMask()

            let keyExchangeSync = keyExchange.keyExchangeMessage(with: .syn)
            Logging.log("mmsdk| >>> Initiating key exchange: \(keyExchangeSync) <<<")
            await emit(ClientEvent.keyExchange, keyExchangeSync)
            await sendMessage(keyExchangeSync, encrypt: false)
        }
        
        Task {
            let data = await connectionClient.on("join_ack")
            Logging.log("mmsdk| >>> Server confirms my join: \(data) <<<")
        }
        
        Task {
            let data = await connectionClient.on(ClientEvent.clientsConnected(on: channelId))
            Logging.log("mmsdk| >>> Both clients connected: \(data) <<<")
            connected = true
            
            if keysExchanged {

            } else {
                let keyExchangeSync = keyExchange.keyExchangeMessage(with: .syn)
                await sendMessage(keyExchangeSync, encrypt: false)
            }
        }
    }
    
    private func handleReceiveDisonnection(on channelId: String) {
        Task {
            let _ = await connectionClient.on(ClientEvent.clientDisconnected(on: channelId))
            Logging.log("mmsdk| Clients disconnected on \(channelId)")
            
            if !self.connectionPaused {
                self.connected = false
                self.keysExchanged = false
                self.channelId = ""
                // Ethereum.disconnect()
            }
        }
    }
    
    private func handleReceiveMessage(on channelId: String) {
        Task {
            let _ = await connectionClient.on(ClientEvent.keysExchanged)
            Logging.log("mmsdk| Keys exchanged")
            await sendOriginatorInfo()
        }
        
        Task {
            let data = await connectionClient.on(ClientEvent.message(on: channelId))
            Logging.log("mmsdk| Received message: \(data)")
        }
    }
    
    public func sendMessage<T: Codable & SocketData>(_ message: T, encrypt: Bool) async {
        if encrypt && !keyExchange.keysExchanged {
            Logging.log("mmsdk| Keys not exchanged")
            return
        }
        
        if encrypt {
            let encryptedMessage = try? keyExchange.encryptMessage(message)
            await emit(
                ClientEvent.message,
                Message(
                    id: channelId,
                    message: encryptedMessage ?? ""))
        } else {
            await emit(
                ClientEvent.message,
                message)
        }
    }
}

private extension Connection {
    func emit(_ event: String, _ item: SocketData) async {
        await connectionClient.emit(event, item)
    }
}

private extension Connection {
    struct OriginatorInfo: Codable, SocketData {
        let title: String
        let url: String
        
        func socketRepresentation() -> SocketData {
            ["title": title, "url": url]
        }
    }
    
    struct Message<T: Codable & SocketData>: SocketData {
        //let type: KeyExchangeStep
        var id: String
        var message: T
        
        func socketRepresentation() -> SocketData {
            ["id": id, "message": message]
        }
    }
    
    struct RequestInfo: Codable, SocketData {
        let type: String
        let originator: OriginatorInfo
        
        func socketRepresentation() -> SocketData {
            ["type": type, "originator": originator]
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
            Logger().log(
                level: .error,
                "\(error.localizedDescription)")
        }
        return nil
    }
}
