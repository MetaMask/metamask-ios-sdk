//
//  Dependencies.swift
//  metamask-ios-sdk
//

import Foundation

final class Dependencies {
    static let shared = Dependencies()
    
    lazy var network: any Networking = Network()
    lazy var tracker: Tracking = Analytics(network: network, debug: true)
    lazy var store: SecureStore = Keychain(service: SDKInfo.bundleIdentifier)
    lazy var sessionManager: SessionManager = SessionManager(store: store, sessionDuration: 24 * 3600 * 7)
    
    lazy var client: CommunicationClient = Client(session: sessionManager, trackEvent: { event, parameters in
        self.trackEvent(event, parameters: parameters)
    })
    
    lazy var ethereum: Ethereum = Ethereum(commClient: client, trackEvent: { event in
        self.trackEvent(event)
    })
    
    func trackEvent(_ event: Event, parameters: [String: Any] = [:]) {
        Task {
            await self.tracker.trackEvent(event, parameters: parameters)
        }
    }
}
