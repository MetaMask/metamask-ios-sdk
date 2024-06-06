//
//  MockSessionManager.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk

class MockSessionManager: SessionManager {
    var fetchSessionConfigCalled = false
    var clearCalled = false
    private let DEFAULT_SESSION_DURATION: TimeInterval = 24 * 7 * 3600

    override func fetchSessionConfig() -> (SessionConfig, Bool) {
        fetchSessionConfigCalled = true
        return (SessionConfig(sessionId: "mockSessionId", expiry: Date(timeIntervalSinceNow: DEFAULT_SESSION_DURATION)), false)
    }

    override func clear() {
        clearCalled = true
    }
}
