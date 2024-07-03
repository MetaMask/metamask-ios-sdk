//
//  SocketClient.swift
//

import OSLog
import UIKit
import Combine
import Foundation

public class SocketClient: CommClient {
    public var appMetadata: AppMetadata?
    private let session: SessionManager
    let keyExchange: KeyExchange
    private let channel: SocketChannel
    let urlOpener: URLOpener

    var channelId: String = ""

    public var isConnected: Bool {
        channel.isConnected
    }

    public var networkUrl: String {
        get {
            channel.networkUrl
        } set {
            channel.networkUrl = newValue
        }
    }

    public var sessionDuration: TimeInterval {
        get {
            session.sessionDuration
        } set {
            session.sessionDuration = newValue
        }
    }

    var isReady: Bool = false
    var isReconnection = false
    public var onClientsTerminated: (() -> Void)?

    public var handleResponse: (([String: Any]) -> Void)?
    public var trackEvent: ((Event, [String: Any]) -> Void)?

    var requestJobs: [RequestJob] = []

    public var useDeeplinks: Bool = true

    private var _deeplinkUrl: String {
        useDeeplinks ? "metamask:/" : "https://metamask.app.link"
    }

    var deeplinkUrl: String {
        "\(_deeplinkUrl)/connect?channelId="
            + channelId
            + "&comm=socket"
            + "&pubkey="
            + keyExchange.pubkey
            + "&v=2"
    }
    
    private var isV2Protocol: Bool = false

    init(session: SessionManager,
         channel: SocketChannel,
         keyExchange: KeyExchange,
         urlOpener: URLOpener,
         trackEvent: @escaping ((Event, [String: Any]) -> Void)) {
        self.session = session
        self.channel = channel
        self.urlOpener = urlOpener
        self.keyExchange = keyExchange
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

    public func connect(with request: String?) {
        if channel.isConnected { return }

        setupClient()
        if isReconnection {
            track(event: .reconnectionRequest)
        } else {
            track(event: .connectionRequest)
        }
        channel.connect()
    }

    public func disconnect() {
        isReady = false
        channel.disconnect()
        channel.tearDown()
        session.clear()
    }

    public func clearSession() {
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

    public func requestAuthorisation() {
        deeplinkToMetaMask()
    }
}

// MARK: Request jobs

extension SocketClient {
    public func addRequest(_ job: @escaping RequestJob) {
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

extension SocketClient {
    func handleConnection() {
        let channelId = channelId

        // MARK: Connection error event

        channel.on(.error) { data in
            Logging.error("Client connection error: \(data)")
        }

        // MARK: Clients connected event

        channel.on(ClientEvent.clientsConnected(on: channelId)) { [weak self] _ in
            Logging.log("Clients connected")

            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Clients Connected"]
            )
            
            if self?.keyExchange.isKeysExchangedViaV2Protocol ?? false {
                Logging.log("Connected via v2 protocol")
                self?.isReady = true
                self?.runJobs()
            }
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

            self.channel.emit(
                ClientEvent.joinChannel,
                ["channelId": channelId,"clientType": "dapp"])

            if !self.isReady {
                self.deeplinkToMetaMask()
            }
        }
        
        channel.on(ClientEvent.config(on: channelId)) { [weak self] data in
            guard
                let self = self,
                let message = data.first as? [String: Bool],
                let persistence = message["persistence"]
            else { return }
            
            isV2Protocol = persistence
            
            if isV2Protocol {
                isReady = true
                Logging.log("SocketClient:: Channel supports protocol v2 communation")
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

            if isKeyExchangeMessage(message) {
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

            track(event: .disconnected)

            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Clients Disconnected"]
            )

            if !isV2Protocol && !keyExchange.isKeysExchangedViaV2Protocol {
                isReady = false
            }
        }
    }
}

// MARK: Message handling

extension SocketClient {
    func handleReceiveKeyExchange(_ message: [String: Any]) {
        let keyExchangeMessage: SocketMessage<KeyExchangeMessage>

        do {
            keyExchangeMessage = try SocketMessage<KeyExchangeMessage>.message(from: message)
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
            let message = try SocketMessage<String>.message(from: msg)
            try handleEncryptedMessage(message)
            if let ackId = message.ackId {
                Logging.log("Sending ackId \(ackId) for message id \(message.id)")
                channel.emit("ack", [
                    "ackId": ackId,
                    "channelId": channelId,
                    "clientType": message.clientType
                ])
            }
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

    func handleEncryptedMessage(_ message: SocketMessage<String>) throws {
        let decryptedText = try keyExchange.decryptMessage(message.message)

        let json: [String: Any] = try JSONSerialization.jsonObject(
            with: Data(decryptedText.utf8),
            options: []
        )
            as? [String: Any] ?? [:]
        handleResponseMessage(json)
    }

    func handleResponseMessage(_ json: [String: Any]) {
        if json["type"] as? String == "terminate" {
            disconnect()
            onClientsTerminated?()
            session.clear()
            keyExchange.reset()
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
            handleResponse?(data)
        }
    }
}

// MARK: Deeplinking

extension SocketClient {
    func deeplinkToMetaMask() {
        guard
            let urlString = deeplinkUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString)
        else { return }

        urlOpener.open(url)
    }
}

// MARK: Message sending

extension SocketClient {
    func sendOriginatorInfo() {
        let originatorInfo = originatorInfo()
        sendMessage(originatorInfo, encrypt: true)
    }

    public func send(_ message: String, encrypt: Bool) {
        do {
            let encryptedMessage: String = try self.keyExchange.encryptMessage(message)

            let message: SocketMessage = .init(
                id: self.channelId,
                message: encryptedMessage
            )

            self.channel.emit(ClientEvent.message, message)

        } catch {
            Logging.error("\(error.localizedDescription)")
        }
    }

    public func sendMessage<T: CodableData>(_ message: T, encrypt: Bool, options: [String: String] = [:]) {
        if encrypt && !keyExchange.keysExchanged {
            addRequest { [weak self] in
                guard let self = self else { return }
                Logging.log("Resuming sending requests after reconnection")

                do {
                    let encryptedMessage: String = try self.keyExchange.encryptMessage(message)

                    let message: SocketMessage = .init(
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
            if !isReady && !keyExchange.isKeysExchangedViaV2Protocol {
                Logging.log("Connection not ready. Will send once wallet is open again")
                addRequest { [weak self] in
                    guard let self = self else { return }
                    Logging.log("Resuming sending requests")

                    do {
                        let encryptedMessage: String = try self.keyExchange.encryptMessage(message)

                        let message: SocketMessage = .init(
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
                    let message: SocketMessage = .init(
                        id: channelId,
                        message: encryptedMessage
                    )

                    channel.emit(ClientEvent.message, message)

                } catch {
                    Logging.error("\(error.localizedDescription)")
                }
            }
        } else {
            let message = SocketMessage(
                id: channelId,
                message: message
            )

            self.channel.emit(ClientEvent.message, message)
        }
    }
}

// MARK: Analytics

extension SocketClient {
    public func track(event: Event) {
        let parameters: [String: Any] = [
            "id": channelId,
            "commLayer": "socket",
            "sdkVersion": SDKInfo.version,
            "url": appMetadata?.url ?? "",
            "dappId": SDKInfo.bundleIdentifier ?? "N/A",
            "title": appMetadata?.name ?? "",
            "platform": SDKInfo.platform
        ]

        trackEvent?(event, parameters)
    }
}
