//
//  DeeplinkClientTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
import metamask_ios_sdk

class DeeplinkClientTests: XCTestCase {
    var deeplinkClient: DeeplinkClient!
    var deeplinkManager: DeeplinkManager!
    
    var secureStore: SecureStore!
    var keyExchange: KeyExchange!
    var sessionManager: SessionManager!
    
    private let DAPP_SCHEME = "testDapp"
    
    override func setUp() {
        super.setUp()
        deeplinkManager = DeeplinkManager()
        
        secureStore = Keychain(service: "com.example.deeplinkTestKeychain")
        keyExchange = KeyExchange()
        sessionManager = SessionManager(store: secureStore, sessionDuration: 3600)
        deeplinkClient = DeeplinkClient(
            session: sessionManager,
            keyExchange: keyExchange,
            deeplinkManager: deeplinkManager,
            dappScheme: DAPP_SCHEME)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testConnectIsTracked() {
        var tracked = false
        var trackedEvent: Event!
        
        deeplinkClient.trackEvent = { event, _ in
            tracked = true
            trackedEvent = event
        }
        
        deeplinkClient.connect()
        
        XCTAssert(tracked)
        XCTAssert(trackedEvent == .connectionRequest)
    }
    
    func testDisconnectIsTracked() {
        var tracked = false
        var trackedEvent: Event!
        
        deeplinkClient.trackEvent = { event, _ in
            tracked = true
            trackedEvent = event
        }
        
        deeplinkClient.disconnect()
        
        XCTAssert(tracked)
        XCTAssert(trackedEvent == .disconnected)
    }
    
    func testTerminateConnectionIsTracked() {
        var tracked = false
        var trackedEvent: Event!
        
        deeplinkClient.trackEvent = { event, _ in
            tracked = true
            trackedEvent = event
        }
        
        deeplinkClient.terminateConnection()
        
        XCTAssert(tracked)
        XCTAssert(trackedEvent == .disconnected)
    }
    
    func testAddJobIncreasesQueuedJobsByOne() {
        let job: RequestJob = {}
        XCTAssertEqual(deeplinkClient.requestJobs.count, 0)
        deeplinkClient.addRequest(job)
        XCTAssertEqual(deeplinkClient.requestJobs.count, 1)
    }
    
    func testRunQueuedJobsClearsJobQueue() {
        let job1: RequestJob = {}
        let job2: RequestJob = {}
        deeplinkClient.addRequest(job1)
        deeplinkClient.addRequest(job2)
        XCTAssertEqual(deeplinkClient.requestJobs.count, 2)
        
        deeplinkClient.runQueuedJobs()
        XCTAssertEqual(deeplinkClient.requestJobs.count, 0)
    }
    
    func testTypeReadyMessageRunsQueuedJobs() {
        let job: RequestJob = {}
        deeplinkClient.addRequest(job)
        
        XCTAssertEqual(deeplinkClient.requestJobs.count, 1)
        
        let response = ["type": "ready"]
        let message = response.toJsonString() ?? ""
        
        deeplinkClient.handleMessage(message)
        
        XCTAssertEqual(deeplinkClient.requestJobs.count, 0)
    }
    
    func testTypeTerminateMessageDisconnects() {
        var trackedEvent: Event!
        let response = ["type": "terminate"]
        let message = response.toJsonString() ?? ""
        
        deeplinkClient.trackEvent = { event, _ in
            trackedEvent = event
        }
        
        deeplinkClient.handleMessage(message)
        
        XCTAssertEqual(trackedEvent, .disconnected)
    }
}
