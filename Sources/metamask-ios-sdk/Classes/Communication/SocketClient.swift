//
//  SocketClient.swift
//

import OSLog
import UIKit
import Combine
import SocketIO
import Foundation

protocol CommunicationClient: AnyObject {
    var clientName: String { get }
    var dapp: Dapp? { get set }
    var isConnected: Bool { get set }
    var serverUrl: String { get set }

    var onClientsReady: (() -> Void)? { get set }
    var tearDownConnection: (() -> Void)? { get set }
    var receiveEvent: (([String: Any]) -> Void)? { get set }
    var receiveResponse: ((String, [String: Any]) -> Void)? { get set }

    func connect()
    func disconnect()
    func enableTracking(_ enable: Bool)
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool)
}

class SocketClient: CommunicationClient {
    var dapp: Dapp?
    private var tracker: Tracking
    private var keyExchange = KeyExchange()
    private let channel = SocketChannel()

    private var channelId: String = UUID().uuidString
    private var connectionPaused: Bool = false
    private var restartedConnection = false

    var clientName: String {
        "socket"
    }

    var serverUrl: String {
        get {
            channel.serverUrl
        } set {
            channel.serverUrl = newValue
        }
    }

    var isConnected: Bool = false
    var onClientsReady: (() -> Void)?
    var tearDownConnection: (() -> Void)?
    var onClientsDisconnected: (() -> Void)?

    var receiveEvent: (([String: Any]) -> Void)?
    var receiveResponse: ((String, [String: Any]) -> Void)?

    var deeplinkUrl: String {
        "https://metamask.app.link/connect?channelId="
            + channelId
            + "&comm=socket"
            + "&pubkey="
            + keyExchange.pubkey
    }

    init(tracker: Tracking) {
        self.tracker = tracker
        setupClient()
    }

    private func setupClient() {
        handleReceiveMessages()
        handleConnection()
        handleDisconnection()
    }

    private func resetClient() {
        isConnected = false
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

            if !self.keyExchange.keysExchanged {
                let keyExchangeSync = self.keyExchange.message(type: .syn)
                self.sendMessage(keyExchangeSync, encrypt: false)
            }
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

    func handleMessage(_ message: [String: Any]) {
        if
            KeyExchange.isHandshakeRestartMessage(message) {
            keyExchange.restart()
            isConnected = true
            connectionPaused = false
            restartedConnection = true

            if
                let keyExchangeMessage = Message<KeyExchangeMessage>.message(from: message),
                let nextKeyExchangeMessage = keyExchange.nextMessage(keyExchangeMessage.message) {
                sendMessage(nextKeyExchangeMessage, encrypt: false)
            }
        } else {
            guard let message = Message<String>.message(from: message) else {
                Logging.error("Could not handle message")
                return
            }

            do {
                try handleEncryptedMessage(message)
            } catch {
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

        if json["type"] as? String == "pause" {
            Logging.log("Connection has been paused")
            connectionPaused = true
        } else if json["type"] as? String == "ready" {
            Logging.log("Connection is ready")
            connectionPaused = false
            onClientsReady?()
        } else if json["type"] as? String == "wallet_info" {
            Logging.log("Received wallet info")
            isConnected = true
            onClientsReady?()
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
            url: dapp?.url
        )

        let requestInfo = RequestInfo(
            type: "originator_info",
            originator: originatorInfo
        )

        sendMessage(requestInfo, encrypt: true)
    }

    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool) {
        let msg = message
        if encrypt && !keyExchange.keysExchanged {
            Logging.error("Attempting to send encrypted message without exchanging encryption keys")
            return
        }

        if encrypt {
            do {
                var encryptedMessage: String = try keyExchange.encryptMessage(message)

                if connectionPaused {
                    Logging.log("Connection paused. Will send once wallet is open again")
                    onClientsReady = { [weak self] in
                        guard let self = self else { return }
                        Logging.log("Resuming sending requests")
                        
                        if self.restartedConnection {
                            // their public key has changed, encrypt message again
                            do {
                                encryptedMessage = try self.keyExchange.encryptMessage(message)
                            } catch {
                                Logging.error("\(error.localizedDescription)")
                            }
                            self.restartedConnection = false
                        }
                        let message: Message = .init(
                            id: self.channelId,
                            message: encryptedMessage
                        )
                        self.channel.emit(ClientEvent.message, message)
                    }
                } else {
                    let message: Message = .init(
                        id: channelId,
                        message: encryptedMessage
                    )
                    channel.emit(ClientEvent.message, message)
                }
            } catch {
                Logging.error("\(error.localizedDescription)")
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
                "platform": UIDevice.current.systemName
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
