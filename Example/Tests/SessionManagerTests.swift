//
//  SessionManagerTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
import metamask_ios_sdk

class SessionManagerTests: XCTestCase {
    var keychain: SecureStore!
    var sessionManager: SessionManager!
    let sessionDuration: TimeInterval = 3600
    
    override func setUp() {
        super.setUp()
        keychain = Keychain(service: "com.example.testKeychain")
        sessionManager = SessionManager(store: keychain, sessionDuration: sessionDuration)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testInitiallyNoSessionExists() {
        let fetchCurrentSessionConfig = sessionManager.fetchCurrentSessionConfig()
        XCTAssertNil(fetchCurrentSessionConfig)
    }
    
    func testNewSessionConfigIsValid() {
        sessionManager.createNewSessionConfig()
        guard let newSessionConfig = sessionManager.fetchCurrentSessionConfig() else {
            XCTFail("Could not create new session")
            return
        }
        XCTAssertTrue(newSessionConfig.isValid)
    }
    
    func testClearSessionDeletesCurrentSession() {
        sessionManager.createNewSessionConfig()
       
        let sessionConfig = sessionManager.fetchCurrentSessionConfig()
        XCTAssertNotNil(sessionConfig)
        
        sessionManager.clear()
        
        let newSessionConfig = sessionManager.fetchCurrentSessionConfig()
        XCTAssertNil(newSessionConfig)
    }
    
    func testFetchSessionAfterClearReturnsNewSession() {
        sessionManager.createNewSessionConfig()
       
        let sessionConfig = sessionManager.fetchCurrentSessionConfig()
        
        sessionManager.clear()
        
        let newSessionConfig = sessionManager.fetchCurrentSessionConfig()
        XCTAssertNotEqual(sessionConfig?.sessionId, newSessionConfig?.sessionId)
    }
    
    func testFetchSessionAfterSettingInvalidSessionCreatesANewValidSession() {
        sessionManager = SessionManager(store: keychain, sessionDuration: -sessionDuration)
        sessionManager.createNewSessionConfig()
       
        guard let sessionConfig = sessionManager.fetchCurrentSessionConfig() else {
            XCTFail("Could not create new session")
            return
        }
        
        XCTAssertFalse(sessionConfig.isValid)
        
        let newSessionConfig = sessionManager.fetchSessionConfig().0

        XCTAssertTrue(newSessionConfig.isValid)
    }
}
