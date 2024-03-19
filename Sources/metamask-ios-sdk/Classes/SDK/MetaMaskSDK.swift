//
//  MetaMaskSDK.swift
//

import SwiftUI
import Combine
import Foundation

class SDKWrapper {
    var sdk: MetaMaskSDK?
    static let shared = SDKWrapper()
}

public class MetaMaskSDK: ObservableObject {
    private var tracker: Tracking = Analytics.live
    private let ethereum: Ethereum = .live
    
    /// The active/selected MetaMask account chain
    @Published public var chainId: String = ""
    /// Indicated whether connected to MetaMask
    @Published public var connected: Bool = false
    
    /// The active/selected MetaMask account address
    @Published public var account: String = ""
    
    private var sharedInstance: MetaMaskSDK?

    /// In debug mode we track three events: connection request, connected, disconnected, otherwise no tracking
    public var enableDebug: Bool = true {
        didSet {
            tracker.enableDebug = enableDebug
        }
    }
    
    public var networkUrl: String {
        get {
            ethereum.commClient.networkUrl
        } set {
            ethereum.commClient.networkUrl = newValue
        }
    }

    public var useDeeplinks: Bool = false {
        didSet {
            ethereum.commClient.useDeeplinks = useDeeplinks
        }
    }

    public var sessionDuration: TimeInterval {
        get {
            ethereum.commClient.sessionDuration
        } set {
            ethereum.commClient.sessionDuration = newValue
        }
    }

    private init(appMetadata: AppMetadata, communicationLayer: CommLayer, enableDebug: Bool, sdkOptions: SDKOptions?) {
        self.ethereum.delegate = self
        self.ethereum.commClient.communicationLayer = communicationLayer
        self.ethereum.sdkOptions = sdkOptions
        self.ethereum.updateMetadata(appMetadata)
        self.tracker.enableDebug = enableDebug
        setupAppLifeCycleObservers()
    }
    
    public static func shared(_ appMetadata: AppMetadata, 
                              communicationLayer: CommLayer = .socket,
                              enableDebug: Bool = true,
                              sdkOptions: SDKOptions?) -> MetaMaskSDK {
        guard let sdk = SDKWrapper.shared.sdk else {
            let metamaskSdk = MetaMaskSDK(
                appMetadata: appMetadata,
                communicationLayer: communicationLayer,
                enableDebug: enableDebug,
                sdkOptions: sdkOptions)
            SDKWrapper.shared.sdk = metamaskSdk
            return metamaskSdk
        }
        return sdk
    }
}

public extension MetaMaskSDK {
    func connect() async -> Result<String, RequestError> {
        await ethereum.connect()
    }
    
    func connectAndSign(message: String) async -> Result<String, RequestError>  {
       await ethereum.connectAndSign(message: message)
    }
    
    func connectWith<T: CodableData>(_ request: EthereumRequest<T>) async -> Result<String, RequestError> {
        await ethereum.connectWith(request)
    }

    func disconnect() {
        ethereum.disconnect()
    }
    
    func clearSession() {
        ethereum.clearSession()
    }
    
    func terminateConnection() {
        ethereum.terminateConnection()
    }
    
    func request<T: CodableData>(_ request: EthereumRequest<T>) async -> Result<String, RequestError>  {
       await ethereum.request(request)
    }
    
    func batchRequest<T: CodableData>(_ requests: [EthereumRequest<T>]) async -> Result<[String], RequestError> {
        await ethereum.batchRequest(requests)
    }
}

extension MetaMaskSDK: EthereumEventsDelegate {
    func chainIdChanged(_ chainId: String) {
        self.chainId = chainId
    }
    
    func accountChanged(_ account: String) {
        self.account = account
    }
}

private extension MetaMaskSDK {
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
