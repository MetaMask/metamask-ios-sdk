//
//  SessionManager.swift
//  metamask-ios-sdk
//

import Foundation

public class SessionManager {
    private let store: SecureStore
    private let SESSION_KEY = "session_id"
    private let DEFAULT_SESSION_DURATION: TimeInterval = 24 * 7 * 3600
    
    public var sessionDuration: TimeInterval
    
    public init(store: SecureStore,
                sessionDuration: TimeInterval) {
        self.store = store
        self.sessionDuration = sessionDuration
    }
    
    public func fetchCurrentSessionConfig() -> SessionConfig? {
        let config: SessionConfig? = store.model(for: SESSION_KEY)
        return config
    }
    
    public func createNewSessionConfig() {
        // update session expiry date
        var config = SessionConfig(sessionId: UUID().uuidString,
                                   expiry: Date(timeIntervalSinceNow: sessionDuration))
        if !config.isValid {
            sessionDuration = DEFAULT_SESSION_DURATION
            createNewSessionConfig()
        }
        // persist session config
        if let configData = try? JSONEncoder().encode(config) {
            store.save(data: configData, key: SESSION_KEY)
        }
    }
    
    public func fetchSessionConfig() -> (SessionConfig, Bool) {
        
        if let config = fetchCurrentSessionConfig(), config.isValid {
            return (config, true)
        } else {
            // purge any existing session info
            store.deleteData(for: SESSION_KEY)
            createNewSessionConfig()
            let config = fetchSessionConfig().0
            return (config, false)
        }
    }
    
    public func clear() {
        store.deleteData(for: SESSION_KEY)
    }
}
