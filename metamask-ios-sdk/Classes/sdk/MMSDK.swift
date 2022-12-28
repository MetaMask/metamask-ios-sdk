//
//  MMSDK.swift
//

import SwiftUI
import Combine

protocol SDKDelegate: AnyObject {
    var dapp: Dapp? { get set }
    var onClientsReady: (() -> Void)? { get set }
    
    func connect()
    func disconnect()
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool)
}

public class MMSDK: SDKDelegate {
    public static let shared = MMSDK()
    
    /// In debug mode we track three events: connection request, connected, disconnected, otherwise no tracking
    var enableDebug: Bool = true {
        didSet {
            client.enableTracking(enableDebug)
        }
    }
    
    @ObservedObject public var ethereum = Ethereum()
    
    private var client: CommunicationClient!
    
    var isConnected: Bool {
        client.isConnected
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
        self.client = SocketClient(tracker: tracker)
        
        ethereum.delegate = self
        setupClientCommunication()
    }
    
    func setupClientCommunication() {
        client.receiveEvent = ethereum.receiveEvent
        client.tearDownConnection = ethereum.disconnect
        client.receiveResponse = ethereum.receiveResponse
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
