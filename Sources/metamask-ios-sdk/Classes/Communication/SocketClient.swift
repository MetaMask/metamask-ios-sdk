//
//  SocketClient.swift
//

import OSLog
import UIKit
import Combine
import SocketIO
import Foundation

typealias RequestJob = () -> Void

protocol CommunicationClient: AnyObject {
    var clientName: String { get }
    var dapp: Dapp? { get set }
    var deeplinkUrl: String { get }
    var isConnected: Bool { get set }
    var serverUrl: String { get set }
    var hasValidSession: Bool { get }
    var sessionDuration: TimeInterval { get set }

    var tearDownConnection: (() -> Void)? { get set }
    var receiveEvent: (([String: Any]) -> Void)? { get set }
    var receiveResponse: ((String, [String: Any]) -> Void)? { get set }

    func connect()
    func disconnect()
    func clearSession()
    func enableTracking(_ enable: Bool)
    func addRequest(_ job: @escaping RequestJob)
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool)
}

class SocketClient: CommunicationClient {
    var dapp: Dapp?
    private var tracker: Tracking
    private let store: SecureStore
    private var keyExchange = KeyExchange()
    private let channel = SocketChannel()

    private var channelId: String = ""
    
    private var connectionPaused: Bool = false
    private var restartedConnection = false
    
    private let SESSION_KEY = "session_id"

    var clientName: String {
        "socket"
    }
    
    // 24 hours default
    var sessionDuration: TimeInterval = 24 * 3600 {
        didSet {
            updateSessionConfig()
        }
    }

    var serverUrl: String {
        get {
            channel.serverUrl
        } set {
            channel.serverUrl = newValue
        }
    }
    
    var hasValidSession: Bool {
        sessionConfig?.isValid ?? false
    }

    var isConnected: Bool = false
    var tearDownConnection: (() -> Void)?
    var onClientsDisconnected: (() -> Void)?

    var receiveEvent: (([String: Any]) -> Void)?
    var receiveResponse: ((String, [String: Any]) -> Void)?
    
    var requestJobs: [RequestJob] = []

    var deeplinkUrl: String {
        "https://metamask.app.link/connect?channelId="
            + channelId
            + "&comm=socket"
            + "&pubkey="
            + keyExchange.pubkey
    }
    
    private var sessionConfig: SessionConfig?

    init(store: SecureStore, tracker: Tracking) {
        self.store = store
        self.tracker = tracker
        setupClient()
    }
    
    func setupClient() {
        configureSession()
        handleReceiveMessages()
        handleConnection()
        handleDisconnection()
    }

    func resetClient() {
        isConnected = false
        self.keyExchange.restart()
        tearDownConnection?()
    }

    func connect() {
        trackEvent(.connectionRequest)
        channel.connect()
    }

    func disconnect() {
        isConnected = false
        channel.disconnect()
    }
    
    private func fetchSessionConfig() -> SessionConfig? {
        let config: SessionConfig? = store.model(for: SESSION_KEY)
        return config
    }
    
    private func configureSession() {
        if let config = fetchSessionConfig(), config.isValid {
            channelId = config.sessionId
        } else {
            // purge any existing session info
            store.deleteData(for: SESSION_KEY)
            channelId = UUID().uuidString
        }
        updateSessionConfig()
    }
    
    func clearSession() {
        store.deleteData(for: SESSION_KEY)
        resetClient()
        setupClient()
    }
    
    private func updateSessionConfig() {
        // update session expiry date
        let config = SessionConfig(sessionId: channelId,
                                   expiry: Date(timeIntervalSinceNow: sessionDuration))
        
        sessionConfig = config
        
        // persist session config
        if let configData = try? JSONEncoder().encode(config) {
            store.save(data: configData, key: SESSION_KEY)
        }
    }
}

// MARK: Request jobs

extension SocketClient {
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

private extension SocketClient {
    func handleConnection() {
        let channelId = channelId

        // MARK: Connection error event

        channel.on(clientEvent: .error) { data in
            Logging.error("Client connection error: \(data)")
        }

        // MARK: Clients connected event

        channel.on(ClientEvent.clientsConnected(on: channelId)) { [weak self] data in
            guard let self = self else { return }
            Logging.log("Clients connected: \(data)")

            self.trackEvent(.connected)

            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Clients Connected"]
            )
        }

        // MARK: Socket connected event

        channel.on(clientEvent: .connect) { [weak self] _ in
            guard let self = self else { return }

            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Connected to server"]
            )

            Logging.log("SDK connected to server")

            self.channel.emit(ClientEvent.joinChannel, channelId)

            if !self.isConnected {
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

            if
                let message = message["message"] as? [String: Any],
                message["type"] as? String == KeyExchangeType.start.rawValue {
                self.keyExchange.restart()
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

    // MARK: Socket disconnected event

    func handleDisconnection() {
        channel.on(ClientEvent.clientDisconnected(on: channelId)) { [weak self] _ in
            guard let self = self else { return }
            Logging.log("SDK disconnected")

            self.trackEvent(.disconnected)

            // for debug purposes only
            NotificationCenter.default.post(
                name: NSNotification.Name("connection"),
                object: nil,
                userInfo: ["value": "Clients Disconnected"]
            )

            if !self.connectionPaused {
                self.resetClient()
                self.connectionPaused = true
                self.restartedConnection = true
            }
        }
    }
}

// MARK: Message handling

private extension SocketClient {
    func handleReceiveKeyExchange(_ message: [String: Any]) {
        guard
            let keyExchangeMessage = Message<KeyExchangeMessage>.message(from: message),
            let nextKeyExchangeMessage = keyExchange.nextMessage(keyExchangeMessage.message)
        else { return }

        sendMessage(nextKeyExchangeMessage, encrypt: false)

        if keyExchange.keysExchanged {
            sendOriginatorInfo()
        }
    }

    func handleMessage(_ msg: [String: Any]) {
        guard let message = Message<String>.message(from: msg) else {
            Logging.error("Could not parse message \(msg)")
            return
        }

        do {
            try handleEncryptedMessage(message)
        } catch {
            Logging.error(error.localizedDescription)
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
            keyExchange.restart()
        } else if json["type"] as? String == "pause" {
            Logging.log("Connection has been paused")
            connectionPaused = true
        } else if json["type"] as? String == "ready" {
            Logging.log("Connection is ready")
            isConnected = true
            connectionPaused = false
            runJobs()
        } else if json["type"] as? String == "wallet_info" {
            Logging.log("Received wallet info")
            isConnected = true
            connectionPaused = false
        } else if let data = json["data"] as? [String: Any] {
            if let id = data["id"] as? String {
                receiveResponse?(id, data)
            } else {
                receiveEvent?(data)
            }
        }
    }
}

// MARK: Deeplinking

private extension SocketClient {
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

extension SocketClient {
    func sendOriginatorInfo() {
        let originatorInfo = OriginatorInfo(
            title: dapp?.name,
            url: dapp?.url,
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
                    // debug code
                    let data = try! JSONEncoder().encode(message)
                    let message: Message = .init(
                        id: self.channelId,
                        message: encryptedMessage,
                        plaintext: String(data: data, encoding: .utf8)
                    )
                    self.channel.emit(ClientEvent.message, message)
                } catch {
                    Logging.error("Could not encrypt message")
                }
            }
        } else if encrypt {
            if connectionPaused {
                Logging.log("Connection paused. Will send once wallet is open again")
                addRequest { [weak self] in
                    guard let self = self else { return }
                    Logging.log("Resuming sending requests after connection pause")
                    
                    do {
                        let encryptedMessage: String = try self.keyExchange.encryptMessage(message)
                        // debug code
                        let data = try! JSONEncoder().encode(message)
                        let message: Message = .init(
                            id: self.channelId,
                            message: encryptedMessage,
                            plaintext: String(data: data, encoding: .utf8)
                        )
                        self.channel.emit(ClientEvent.message, message)
                        
                    } catch {
                        Logging.error("\(error.localizedDescription)")
                    }
                }
            } else {
                do {
                    let encryptedMessage: String = try self.keyExchange.encryptMessage(message)
                    let data = try! JSONEncoder().encode(message)
                    let message: Message = .init(
                        id: channelId,
                        message: encryptedMessage,
                        plaintext: String(data: data, encoding: .utf8)
                    )
                    channel.emit(ClientEvent.message, message)
                    
                } catch {
                    Logging.error("\(error.localizedDescription)")
                }
            }
        } else {
            let data = try! JSONEncoder().encode(message)
            let message = Message(
                id: channelId,
                message: message,
                plaintext: String(data: data, encoding: .utf8)
            )

            channel.emit(ClientEvent.message, message)
        }
    }
}

// MARK: Analytics

extension SocketClient {
    func trackEvent(_ event: Event) {
        let id = channelId
        var parameters: [String: Any] = ["id": id]

        switch event {
        case .connected, .disconnected:
            break
        case .connectionRequest:
            let additionalParams: [String: Any] = [
                "commLayer": "socket",
                "sdkVersion": SDKInfo.version,
                "url": dapp?.url ?? "",
                "title": dapp?.name ?? "",
                "platform": SDKInfo.platform
            ]
            parameters.merge(additionalParams) { current, _ in current }
        }

        Task { [parameters] in
            await self.tracker.trackEvent(
                event,
                parameters: parameters
            )
        }
    }

    func enableTracking(_ enable: Bool) {
        tracker.enableDebug = enable
    }
}
