//
//  DeeplinkClientTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class DeeplinkClientTests: XCTestCase {
    var deeplinkClient: DeeplinkClient!
    var mockDeeplinkManager: MockDeeplinkManager!

    var secureStore: SecureStore!
    var mockURLOpener: MockURLOpener!
    var mockKeyExchange: MockKeyExchange!
    var mockSessionManager: MockSessionManager!

    private let DAPP_SCHEME = "testDapp"

    override func setUp() {
        super.setUp()
        mockDeeplinkManager = MockDeeplinkManager()

        secureStore = Keychain(service: "com.example.deeplinkTestKeychain")
        mockKeyExchange = MockKeyExchange()
        mockURLOpener = MockURLOpener()
        mockSessionManager = MockSessionManager(store: secureStore, sessionDuration: 3600)
        deeplinkClient = DeeplinkClient(
            session: mockSessionManager,
            keyExchange: mockKeyExchange,
            deeplinkManager: mockDeeplinkManager,
            dappScheme: DAPP_SCHEME,
            urlOpener: mockURLOpener
        )
    }
    
    func testSetupClient() {
        XCTAssertEqual(deeplinkClient.channelId, "mockSessionId")
    }
    
    func testSetupCallbacks() {
        XCTAssertNotNil(deeplinkClient.deeplinkManager.onReceiveMessage)
        XCTAssertNotNil(deeplinkClient.deeplinkManager.decryptMessage)
    }
    
    func testClearSession() {
        deeplinkClient.clearSession()
        XCTAssertTrue(mockSessionManager.clearCalled)
        XCTAssertTrue(mockSessionManager.fetchSessionConfigCalled)
        XCTAssertEqual(deeplinkClient.channelId, "mockSessionId")
    }
    
    func testGetSessionDuration() {
        XCTAssertEqual(deeplinkClient.sessionDuration, 3600)
    }
    
    func testSetSessionDuration() {
        deeplinkClient.sessionDuration = 60
        XCTAssertEqual(deeplinkClient.sessionDuration, 60)
    }
    
    func testHandleUrl() {
        let url = URL(string: "https://example.com")!
        deeplinkClient.handleUrl(url)
        XCTAssertTrue(mockDeeplinkManager.handleUrlCalled)
    }
    
    func testConnect() {
        deeplinkClient.connect(with: "testRequest")
        let openedUrl = mockURLOpener.openedURL?.absoluteString ?? ""
        XCTAssertTrue(openedUrl.contains("metamask://connect?"))
        XCTAssertTrue(openedUrl.contains("?scheme=testDapp"))
        XCTAssertTrue(openedUrl.contains("&channelId=mockSessionId"))
        XCTAssertTrue(openedUrl.contains("&comm=deeplinking"))
        XCTAssertTrue(openedUrl.contains("&request=testRequest"))
    }
    
    func testSendMessage() {
        deeplinkClient.sendMessage("testMessage")
        XCTAssertEqual(mockURLOpener.openedURL?.absoluteString, "metamask://testMessage")
    }
    
    func testSendMessageWithDeeplink() {
        let account = "testAccount"
        let chainId = "0x1"
        let options: [String: String] = ["account": account, "chainId": chainId]
        deeplinkClient.sendMessage(.mmsdk(message: "testMessage", pubkey: nil, channelId: "testChannelId"), options: options)
        let openedUrl = mockURLOpener.openedURL?.absoluteString ?? ""
        let expectedDeeplink = "metamask://mmsdk?scheme=testDapp&message=testMessage&channelId=testChannelId&account=\(account)@\(chainId)"
        XCTAssertEqual(openedUrl, expectedDeeplink)
    }
    
    func testSendStringMessageWithOptions() {
        let account = "testAccount"
        let chainId = "0x1"
        let message = "testMessage"
        let based64Message = message.base64Encode() ?? ""
        let options: [String: String] = ["account": account, "chainId": chainId]
        
        deeplinkClient.sendMessage(message, encrypt: false, options: options)
        let openedUrl = mockURLOpener.openedURL?.absoluteString ?? ""
        let expectedDeeplink = "metamask://mmsdk?scheme=testDapp&message=\(based64Message)&channelId=mockSessionId&account=\(account)@\(chainId)"
        XCTAssertEqual(openedUrl, expectedDeeplink)
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
