//
//  Dependencies.swift
//  metamask-ios-sdk
//

import Foundation

public final class Dependencies {
    public static let shared = Dependencies()
    
    public lazy var network: any Networking = Network()
    public lazy var tracker: Tracking = Analytics(network: network, debug: true)
    public lazy var store: SecureStore = Keychain(service: SDKInfo.bundleIdentifier)
    public lazy var sessionManager: SessionManager = SessionManager(store: store, sessionDuration: 24 * 3600 * 7)
    
    public lazy var client: CommunicationClient = Client(
        session: sessionManager,
        communicationLayer: .socket,
        trackEvent: { event, parameters in
            self.trackEvent(event, parameters: parameters)
        }
    )
    
    public lazy var ethereum: Ethereum = Ethereum(commClient: client, trackEvent: { event in
        self.trackEvent(event)
    })
    
    public lazy var keyExchange: KeyExchange = KeyExchange()
    
    public lazy var deeplinkManager: DeeplinkManager = DeeplinkManager(keyExchange: keyExchange)
    
    public lazy var deeplinkClient: DeeplinkClient = DeeplinkClient(session: sessionManager, deeplinkManager: deeplinkManager)
    
    public func trackEvent(_ event: Event, parameters: [String: Any] = [:]) {
        Task {
            await self.tracker.trackEvent(event, parameters: parameters)
        }
    }
}
