//
//  MetaMaskSDK.swift
//

import SwiftUI
import Combine

protocol SDKDelegate: AnyObject {
    var dapp: Dapp? { get set }
    var deeplinkUrl: String { get }
    var enableDebug: Bool { get set }
    var networkUrl: String { get set }
    func connect()
    func disconnect()
    func clearSession()
    func addRequest(_ job: @escaping RequestJob)
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool)
}

public class MetaMaskSDK: ObservableObject, SDKDelegate {
    private var client: CommunicationClient!

    /// Shared instance of the SDK through which Ethereum is accessed
    public static let shared = MetaMaskSDK()

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
    
    public var hasValidSession: Bool {
        client.hasValidSession
    }
    
    public var sessionDuration: TimeInterval {
        get {
            client.sessionDuration
        } set {
            client.sessionDuration = newValue
        }
    }

    var networkUrl: String {
        get {
            client.serverUrl
        } set {
            client.serverUrl = newValue
        }
    }
    
    var deeplinkUrl: String {
        client.deeplinkUrl
    }

    var dapp: Dapp? {
        didSet {
            client.dapp = dapp
        }
    }
    
    func addRequest(_ job: @escaping RequestJob) {
        client.addRequest(job)
    }
    
    public convenience init(store: SecureStore = Keychain(service: SDKInfo.bundleIdentifier)) {
        self.init(client: SocketClient(store: store, tracker: Analytics(debug: true)))
    }

    init(client: CommunicationClient) {
        self.client = client

        ethereum.delegate = self
        setupClientCommunication()
        setupAppLifeCycleObservers()
    }
}

private extension MetaMaskSDK {
    func setupClientCommunication() {
        client.receiveEvent = ethereum.receiveEvent
        client.tearDownConnection = ethereum.disconnect
        client.receiveResponse = ethereum.receiveResponse
        client.onClientsTerminated = ethereum.terminateConnection
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

extension MetaMaskSDK {
    func connect() {
        client.connect()
    }

    func disconnect() {
        client.disconnect()
    }
    
    func clearSession() {
        client.clearSession()
    }

    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool) {
        client.sendMessage(message, encrypt: encrypt)
    }
}
