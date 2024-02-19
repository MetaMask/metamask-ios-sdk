//
//  SocketClient.swift
//

import OSLog
import UIKit
import Combine
import Foundation

public class Client: CommunicationClient {
    var appMetadata: AppMetadata?
    private let session: SessionManager
    private var keyExchange = KeyExchange()
    private let channel = Channel()

    private var channelId: String = ""

    var isConnected: Bool {
        channel.isConnected
    }
    
    var networkUrl: String {
        get {
            channel.networkUrl
        } set {
            channel.networkUrl = newValue
        }
    }
    
    var sessionDuration: TimeInterval {
        get {
            session.sessionDuration
        } set {
            session.sessionDuration = newValue
        }
    }
    
    private var isReady: Bool = false
    private var isReconnection = false
    var tearDownConnection: (() -> Void)?
    var onClientsTerminated: (() -> Void)?

    var receiveEvent: (([String: Any]) -> Void)?
    var receiveResponse: ((String, [String: Any]) -> Void)?
    
    var trackEvent: ((Event, [String: Any]) -> Void)?
    
    var requestJobs: [RequestJob] = []
    
    var useDeeplinks: Bool = true
    
    private var _deeplinkUrl: String {
        useDeeplinks ? "metamask:/" : "https://metamask.app.link"
    }

    var deeplinkUrl: String {
        "\(_deeplinkUrl)/connect?channelId="
            + channelId
            + "&comm=socket"
            + "&pubkey="
            + keyExchange.pubkey
    }

    init(session: SessionManager, trackEvent: @escaping ((Event, [String: Any]) -> Void)) {
        self.session = session
        self.trackEvent = trackEvent
    }
    
    func setupClient() {
        let sessionInfo = session.fetchSessionConfig()
        channelId = sessionInfo.0.sessionId
        isReconnection = sessionInfo.1
        handleReceiveMessages()
        handleConnection()
        handleDisconnection()
    }

    func connect() {
        if channel.isConnected { return }
        
        setupClient()
        if isReconnection {
            track(event: .reconnectionRequest)
        } else {
            track(event: .connectionRequest)
        }
        channel.connect()
    }

    func disconnect() {
        isReady = false
        channel.disconnect()
        channel.tearDown()
    }
    
    func clearSession() {
        channelId = ""
        session.clear()
        disconnect()
        keyExchange.reset()
    }
    
    private func initiateKeyExchange() {
        keyExchange.reset()
        let keyExchangeStartMessage = KeyExchangeMessage(type: .start, pubkey: nil)
        sendMessage(keyExchangeStartMessage, encrypt: false)
    }
    
    func requestAuthorisation() {
        deeplinkToMetaMask()
    }
}

// MARK: Request jobs

extension Client {
    func addRequest(_ job: @escaping RequestJob) {
        requestJobs.append(job)
    }
    
    func runJobs() {
        while !requestJobs.isEmpty {
            let job = requestJobs.popLast()
            job?()
        }
    }
}

// MARK: Event handling

private extension Client {
    func handleConnection() {
        let channelId = channelId

        // MARK: Connection error event

        channel.on(.error) { data in
            Logging.error("Client connection error: \(data)")
        }

        // MARK: Clients connected event

        channel.on(ClientEvent.clientsConnected(on: channelId)) { data in
            Logging.log("Clients connected")

            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Clients Connected"]
            )
        }

        // MARK: Socket connected event

        channel.on(.connect) { [weak self] _ in
            guard let self = self else { return }

            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Connected to server"]
            )

            Logging.log("SDK connected to server")

            self.channel.emit(ClientEvent.joinChannel, channelId)

            if !self.isReady {
                self.deeplinkToMetaMask()
            }
        }
    }

    // MARK: New message event

    func handleReceiveMessages() {
        channel.on(ClientEvent.message(on: channelId)) { [weak self] data in
            guard
                let self = self,
                let message = data.first as? [String: Any]
            else { return }

            if !self.isValidMessage(message: message) {
                return
            }
            
            if !self.keyExchange.keysExchanged {
                // Exchange keys
                self.handleReceiveKeyExchange(message)
            } else {
                // Decrypt message
                self.handleMessage(message)
            }
        }
    }
    
    func isValidMessage(message: [String: Any]) -> Bool {
        if
            let message = message["message"] as? [String: Any],
            let type = message["type"] as? String {
            if type == "ping" {
                return false
            }
            
            if type.contains("key_handshake") {
                return true
            } else if !keyExchange.keysExchanged {
                return false
            }
        }
        
        return true
    }
    
    func isKeyExchangeMessage(_ message: [String: Any]) -> Bool {
        if
            let msg = message["message"] as? [String: Any],
            let type = msg["type"] as? String,
            type.contains("key_handshake") {
            return true
        }
        
        return false
    }

    // MARK: Socket disconnected event

    func handleDisconnection() {
        channel.on(ClientEvent.clientDisconnected(on: channelId)) { [weak self] _ in
            guard let self = self else { return }
            Logging.log("SDK disconnected")

            self.track(event: .disconnected)

            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Clients Disconnected"]
            )

            self.isReady = false
        }
    }
}

// MARK: Message handling

private extension Client {
    func handleReceiveKeyExchange(_ message: [String: Any]) {
        let keyExchangeMessage: Message<KeyExchangeMessage>
        
        do {
            keyExchangeMessage = try Message<KeyExchangeMessage>.message(from: message)
        } catch {
            initiateKeyExchange()
            return
        }
        
        guard let nextKeyExchangeMessage = keyExchange.nextMessage(keyExchangeMessage.message) else {
            track(event: .connected)
            return
        }

        sendMessage(nextKeyExchangeMessage, encrypt: false)

        if keyExchange.keysExchanged {
            sendOriginatorInfo()
        }
    }

    func handleMessage(_ msg: [String: Any]) {
        if isKeyExchangeMessage(msg) {
            handleReceiveKeyExchange(msg)
            return
        }
        
        do {
            let message = try Message<String>.message(from: msg)
            try handleEncryptedMessage(message)
        } catch {
            switch error {
            case DecodingError.invalidMessage:
                Logging.error("Could not parse message \(msg)")
                initiateKeyExchange()
            case KeyExchangeError.keysNotExchanged:
                Logging.error("Keys not yet exchanged")
                initiateKeyExchange()
                Logging.error(error.localizedDescription)
            case CryptoError.decryptionFailure:
                Logging.error("Message could not be decrypted: \(error.localizedDescription)")
                initiateKeyExchange()
            default:
                Logging.error(error.localizedDescription)
            }
        }
    }

    func handleEncryptedMessage(_ message: Message<String>) throws {
        let decryptedText = try keyExchange.decryptMessage(message.message)

        let json: [String: Any] = try JSONSerialization.jsonObject(
            with: Data(decryptedText.utf8),
            options: []
        )
            as? [String: Any] ?? [:]

        if json["type"] as? String == "terminate" {
            disconnect()
            onClientsTerminated?()
            Logging.log("Connection terminated")
        } else if json["type"] as? String == "pause" {
            Logging.log("Connection has been paused")
            isReady = true
        } else if json["type"] as? String == "ready" {
            Logging.log("Connection is ready")
            isReady = true
            runJobs()
        } else if json["type"] as? String == "wallet_info" {
            Logging.log("Received wallet info")
            isReady = true
        } else if let data = json["data"] as? [String: Any] {
            if let id = data["id"] {
                if let identifier: Int64 = id as? Int64 {
                    let id: String = String(identifier)
                    receiveResponse?(id, data)
                } else if let identifier: String = id as? String {
                    receiveResponse?(identifier, data)
                }
            } else {
                receiveEvent?(data)
            }
        }
    }
}

// MARK: Deeplinking

private extension Client {
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

extension Client {
    func sendOriginatorInfo() {
        let originatorInfo = OriginatorInfo(
            title: appMetadata?.name,
            url: appMetadata?.url,
            icon: appMetadata?.iconUrl ?? appMetadata?.base64Icon,
            platform: SDKInfo.platform,
            apiVersion: SDKInfo.version
        )

        let requestInfo = RequestInfo(
            type: "originator_info",
            originator: originatorInfo,
            originatorInfo: originatorInfo
        )

        sendMessage(requestInfo, encrypt: true)
    }

    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool) {
        if encrypt && !keyExchange.keysExchanged {
            addRequest { [weak self] in
                guard let self = self else { return }
                Logging.log("Resuming sending requests after reconnection")
                
                do {
                    let encryptedMessage: String = try self.keyExchange.encryptMessage(message)
                    let message: Message = .init(
                        id: self.channelId,
                        message: encryptedMessage
                    )
                    self.channel.emit(ClientEvent.message, message)
                } catch {
                    Logging.error("Could not encrypt message: \(error.localizedDescription)")
                }
            }
            if channelId.isEmpty {
                initiateKeyExchange()
            }
        } else if encrypt {
            if !isReady {
                Logging.log("Connection not ready. Will send once wallet is open again")
                addRequest { [weak self] in
                    guard let self = self else { return }
                    Logging.log("Resuming sending requests after connection pause")
                    
                    do {
                        let encryptedMessage: String = try self.keyExchange.encryptMessage(message)
                        let message: Message = .init(
                            id: self.channelId,
                            message: encryptedMessage
                        )
                        self.channel.emit(ClientEvent.message, message)
                        
                    } catch {
                        Logging.error("\(error.localizedDescription)")
                    }
                }
            } else {
                do {
                    let encryptedMessage: String = try self.keyExchange.encryptMessage(message)
                    let message: Message = .init(
                        id: channelId,
                        message: encryptedMessage
                    )
                    channel.emit(ClientEvent.message, message)
                    
                } catch {
                    Logging.error("\(error.localizedDescription)")
                }
            }
        } else {
            let message = Message(
                id: channelId,
                message: message
            )

            channel.emit(ClientEvent.message, message)
        }
    }
}

// MARK: Analytics

extension Client {
    func track(event: Event) {
        let id = channelId
        var parameters: [String: Any] = ["id": id]

        switch event {
        case .connected,
                .disconnected,
                .reconnectionRequest,
                .connectionAuthorised,
                .connectionRejected:
            break
        case .connectionRequest:
            let additionalParams: [String: Any] = [
                "commLayer": "socket",
                "sdkVersion": SDKInfo.version,
                "url": appMetadata?.url ?? "",
                "title": appMetadata?.name ?? "",
                "platform": SDKInfo.platform
            ]
            parameters.merge(additionalParams) { current, _ in current }
        }
        
        trackEvent?(event, parameters)
    }
}

public extension Client {
    internal static let live: CommunicationClient = Dependencies.shared.client
}
