//
//  MMSDK.swift
//

import SwiftUI
import Combine

protocol SDKDelegate: AnyObject {
    var dapp: Dapp? { get set }
    var enableDebug: Bool { get set }
    var networkUrl: String { get set }
    var onClientsReady: (() -> Void)? { get set }

    func connect()
    func disconnect()
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool)
}

public class MMSDK: ObservableObject, SDKDelegate {
    private var client: CommunicationClient!

    /// Shared instance of the SDK through which Ethereum is accessed
    public static let shared = MMSDK()

    /// Ethereum abstraction via which all requests should be done
    @ObservedObject public var ethereum = Ethereum()

    /// In debug mode we track three events: connection request, connected, disconnected, otherwise no tracking
    public var enableDebug: Bool = true {
        didSet {
            client.enableTracking(enableDebug)
        }
    }

    public var isConnected: Bool {
        client.isConnected
    }

    var networkUrl: String {
        get {
            client.serverUrl
        } set {
            client.serverUrl = newValue
        }
    }

    var dapp: Dapp? {
        didSet {
            client.dapp = dapp
        }
    }

    var onClientsReady: (() -> Void)? {
        didSet {
            client.onClientsReady = onClientsReady
        }
    }

    private init(tracker: Tracking = Analytics(debug: true)) {
        client = SocketClient(tracker: tracker)

        ethereum.delegate = self
        setupClientCommunication()
        setupAppLifeCycleObservers()
    }
}

private extension MMSDK {
    func setupClientCommunication() {
        client.receiveEvent = ethereum.receiveEvent
        client.tearDownConnection = ethereum.disconnect
        client.receiveResponse = ethereum.receiveResponse
    }

    func setupAppLifeCycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startBackgroundTask),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopBackgroundTask),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc
    func startBackgroundTask() {
        BackgroundTaskManager.start()
    }

    @objc
    func stopBackgroundTask() {
        BackgroundTaskManager.stop()
    }
}

extension MMSDK {
    func connect() {
        client.connect()
    }

    func disconnect() {
        client.disconnect()
    }

    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool) {
        client.sendMessage(message, encrypt: encrypt)
    }
}
