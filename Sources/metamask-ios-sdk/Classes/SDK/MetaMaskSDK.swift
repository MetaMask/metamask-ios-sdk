//
//  MetaMaskSDK.swift
//

import SwiftUI
import Combine
import Foundation

protocol SDKDelegate: AnyObject {
    var appMetadata: AppMetadata? { get set }
    var isConnected: Bool { get }
    var enableDebug: Bool { get set }
    var useDeeplinks: Bool { get set }
    var networkUrl: String { get set }
    func connect()
    func disconnect()
    func clearSession()
    func trackEvent(_ event: Event)
    func requestAuthorisation()
    func addRequest(_ job: @escaping RequestJob)
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool)
}

public class MetaMaskSDK: ObservableObject, SDKDelegate {
    private var client: CommunicationClient!
    private var tracker: Tracking

    /// Shared instance of the SDK through which Ethereum is accessed
    public static let shared = MetaMaskSDK()

    /// Ethereum abstraction via which all requests should be done
    @ObservedObject public var ethereum = Ethereum()

    /// In debug mode we track three events: connection request, connected, disconnected, otherwise no tracking
    public var enableDebug: Bool = true {
        didSet {
            tracker.enableDebug = enableDebug
        }
    }
    
    public var useDeeplinks: Bool = false {
        didSet {
            client.useDeeplinks = useDeeplinks
        }
    }

    public var isConnected: Bool {
        client.isConnected
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

    var appMetadata: AppMetadata? {
        didSet {
            client.appMetadata = appMetadata
        }
    }
    
    func addRequest(_ job: @escaping RequestJob) {
        client.addRequest(job)
    }
    
    func requestAuthorisation() {
        client.requestAuthorisation()
    }
    
    public convenience init() {
        self.init(client: Client(session: SessionManager(
            store: Keychain(service: SDKInfo.bundleIdentifier),
            sessionDuration: 24 * 3600 * 7), trackEvent: { event, parameters in
            Task { //[weak self] in
                //await self.tracker.trackEvent(event, parameters: parameters)
            }
            }), tracker: Analytics(network: Network(), debug: true))
    }

    public init(client: CommunicationClient, tracker: Tracking) {
        self.client = client
        self.tracker = tracker

        ethereum.delegate = self
        setupClientCommunication()
        setupAppLifeCycleObservers()
    }
    
    public convenience init(builder: Builder) {
        self.init()
        self.appMetadata = builder.appMetadata
        self.enableDebug = builder.enableDebug
    }
    
    public class Builder {
        var appMetadata: AppMetadata?
        var enableDebug: Bool = false
        
        public func appMetadata(_ metadata: AppMetadata) -> Builder {
            self.appMetadata = metadata
            return self
        }
        
        public func enableDebug(_ enableDebug: Bool) -> Builder {
            self.enableDebug = enableDebug
            return self
        }
        
        public init() {
            
        }
        
        public func build() -> MetaMaskSDK {
            return MetaMaskSDK(builder: self)
        }
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

extension MetaMaskSDK {
    func trackEvent(_ event: Event) {
        client.track(event: event)
    }
}
