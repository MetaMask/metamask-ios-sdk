//
//  SocketClientTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class SocketClientTests: XCTestCase {
    
    var socketClient: SocketClient!
    var secureStore: SecureStore!
    var mockUrlOpener: MockURLOpener!
    var mockSessionManager: MockSessionManager!
    var mockKeyExchange: MockKeyExchange!
    var mockSocketChannel: MockSocketChannel!
    
    override func setUp() {
        super.setUp()
        
        mockUrlOpener = MockURLOpener()
        secureStore = Keychain(service: "com.example.socketTestKeychain")
        mockSessionManager = MockSessionManager(store: secureStore, sessionDuration: 3600)
        mockKeyExchange = MockKeyExchange(storage: secureStore)
        mockSocketChannel = MockSocketChannel()
        
        socketClient = SocketClient(
            session: mockSessionManager,
            channel: mockSocketChannel,
            keyExchange: mockKeyExchange,
            urlOpener: mockUrlOpener,
            trackEvent: { _, _ in })
        socketClient.setupClient()
    }
    
    override func tearDown() {
        mockUrlOpener = nil
        secureStore.deleteAll()
        secureStore = nil
        socketClient = nil
        mockSessionManager = nil
        mockKeyExchange = nil
        mockSocketChannel = nil
        
        super.tearDown()
    }
    
    func testIsConnectedOnConnect() {
        mockSocketChannel.connect()
        XCTAssertTrue(socketClient.isConnected)
    }
    
    func testIsConnectedOnDisconnect() {
        mockSocketChannel.disconnect()
        XCTAssertFalse(socketClient.isConnected)
    }
    
    func testNetworkUrl() {
        socketClient.networkUrl = "newNetworkUrl"
        XCTAssertEqual(socketClient.networkUrl, "newNetworkUrl")
    }
    
    func testSessionDuration() {
        socketClient.sessionDuration = 100.0
        XCTAssertEqual(socketClient.sessionDuration, 100.0)
    }
    
    func testConnect() {
        socketClient.connect(with: nil)
        XCTAssertTrue(mockSocketChannel.isConnected)
    }
    
    func testDisconnect() {
        socketClient.disconnect()
        XCTAssertFalse(mockSocketChannel.isConnected)
    }
    
    func testClearSession() {
        socketClient.clearSession()
        XCTAssertEqual(socketClient.channelId, "")
        XCTAssertFalse(mockSocketChannel.isConnected)
        XCTAssertFalse(mockKeyExchange.keysExchanged)
    }
    
    func testAddRequestAndRunJobs() {
        var jobExecuted = false
        socketClient.addRequest {
            jobExecuted = true
        }
        socketClient.runJobs()
        XCTAssertTrue(jobExecuted)
    }
    
    func testTrackEvent() {
        var trackedEvent: Event?
        var trackedParameters: [String: Any]?
        socketClient.trackEvent = { event, parameters in
            trackedEvent = event
            trackedParameters = parameters
        }
        socketClient.track(event: .connectionRequest)
        XCTAssertEqual(trackedEvent, .connectionRequest)
        XCTAssertNotNil(trackedParameters)
    }
    
    func testUseDeeplinks() {
        socketClient.useDeeplinks = false
        XCTAssertTrue(socketClient.deeplinkUrl.contains("https://metamask.app.link"))
        
        socketClient.useDeeplinks = true
        XCTAssertTrue(socketClient.deeplinkUrl.contains("metamask:/"))
    }
    
    func testRequestAuthorisation() {
        socketClient.useDeeplinks = true

        let sessionId = "mockSessionId"
        let pubkey = "0x12345"
        
        // force keyexchange = true
        mockKeyExchange.keysExchanged = true
        mockKeyExchange.pubkey = pubkey
        
        socketClient.requestAuthorisation()
        
        let openedUrl = mockUrlOpener.openedURL?.absoluteString ?? ""
        let originatorInfoBase64 = socketClient.originatorInfo().originatorInfo.toJsonString()?.base64Encode() ?? ""
        
        let expectedDeeplink = "metamask://connect?channelId="
        + sessionId
        + "&comm=socket"
        + "&pubkey="
        + pubkey
        + "&v=2"
        + "&originatorInfo="
        + originatorInfoBase64
        
        XCTAssertEqual(openedUrl, expectedDeeplink)
    }
    
    func testDeeplinkToMetaMask() {
        socketClient.useDeeplinks = true

        let sessionId = "mockSessionId"
        let pubkey = "0x12345"
        
        // force keyexchange = true
        mockKeyExchange.keysExchanged = true
        mockKeyExchange.pubkey = pubkey
        
        socketClient.deeplinkToMetaMask()
        
        let openedUrl = mockUrlOpener.openedURL?.absoluteString ?? ""
        let originatorInfoBase64 = socketClient.originatorInfo().originatorInfo.toJsonString()?.base64Encode() ?? ""
        
        let expectedDeeplink = "metamask://connect?channelId="
        + sessionId
        + "&comm=socket"
        + "&pubkey="
        + pubkey
        + "&v=2"
        + "&originatorInfo="
        + originatorInfoBase64
        
        XCTAssertEqual(openedUrl, expectedDeeplink)
    }
    
    func testSendMessageUnencrypted() {
        let testMessage = TestCodableData(id: "123", message: "test message")
        socketClient.sendMessage(testMessage, encrypt: false)

        XCTAssertEqual(mockSocketChannel.lastEmittedEvent, ClientEvent.message)
        XCTAssertEqual((mockSocketChannel.lastEmittedMessage as? SocketMessage<TestCodableData>)?.message, testMessage)
    }
    
    func testSendMessageEncryptedKeysExchanged() {
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567")
        // force keyexchange = true
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        // set client as ready
        socketClient.handleResponseMessage(["type": "ready"])
        
        
        let testMessage = TestCodableData(id: "123", message: "test message")

        socketClient.sendMessage(testMessage, encrypt: true)

        XCTAssertEqual(mockSocketChannel.lastEmittedEvent, ClientEvent.message)
        XCTAssertEqual((mockSocketChannel.lastEmittedMessage as? SocketMessage<String>)?.message, "encrypted \(testMessage)")
    }
    
    func testSendMessageEncryptedKeysExchangedNotReadyInV1Protocol() {
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567", v: 1)
        // force keysExchanged = true
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        let testMessage = TestCodableData(id: "123", message: "test message")
        

        socketClient.sendMessage(testMessage, encrypt: true)

        XCTAssertNil(mockSocketChannel.lastEmittedEvent)
        
        // set client as ready
        socketClient.handleResponseMessage(["type": "ready"])
        
        XCTAssertEqual(mockSocketChannel.lastEmittedEvent, ClientEvent.message)
        XCTAssertEqual((mockSocketChannel.lastEmittedMessage as? SocketMessage<String>)?.message, "encrypted \(testMessage)")
    }
    
    func testSendMessageEncryptedKeysExchangedReadyInV2Protocol() {
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567", v: 2)
        // force keysExchanged = true
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        let testMessage = TestCodableData(id: "123", message: "test message")
        

        socketClient.sendMessage(testMessage, encrypt: true)
        
        XCTAssertEqual(mockSocketChannel.lastEmittedEvent, ClientEvent.message)
        XCTAssertEqual((mockSocketChannel.lastEmittedMessage as? SocketMessage<String>)?.message, "encrypted \(testMessage)")
    }
    
    func testSendMessageEncryptedKeysNotExchanged() {
        let testMessage = TestCodableData(id: "123", message: "test message")

        socketClient.sendMessage(testMessage, encrypt: true)

        XCTAssertTrue(socketClient.requestJobs.count == 1)
        XCTAssertEqual(mockSocketChannel.lastEmittedEvent, nil)
    }
    
    // encrypt && !keyExchange.keysExchanged
    func testSendMessageEncryptKeysNotExchanged() {
        
        // set client as ready
        socketClient.handleResponseMessage(["type": "ready"])
        
        
        let testMessage = TestCodableData(id: "123", message: "test message")

        // send message before keys are exchanged
        socketClient.sendMessage(testMessage, encrypt: true)
        
        // no message should be emitted
        XCTAssertNil(mockSocketChannel.lastEmittedEvent)
        
        // force keyexchange = true
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567")
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        // set client as ready
        let readyMessage: [String: Any] = ["type": "ready"]
        socketClient.handleResponseMessage(readyMessage)
    }
    
    func testHandleResponseMessagePause() {
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567")
        // force keyexchange = true
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        let pauseMessage: [String: Any] = ["type": "pause"]
        
        socketClient.handleResponseMessage(pauseMessage)
        
        XCTAssertTrue(socketClient.isReady)
    }
    
    func testHandleResponseMessageReady() {
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567")
        // force keyexchange = true
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        let readyMessage: [String: Any] = ["type": "ready"]
        
        socketClient.handleResponseMessage(readyMessage)
        
        XCTAssertTrue(socketClient.isReady)
    }
    
    func testHandleResponseMessageWalletInfo() {
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567")
        // force keyexchange = true
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        let walletInfoMessage: [String: Any] = ["type": "wallet_info"]
        
        socketClient.handleResponseMessage(walletInfoMessage)
        
        XCTAssertTrue(socketClient.isReady)
    }
    
    func testHandleResponseMessageClientsTerminated() {
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567")
        // force keyexchange = true
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        let expectation = XCTestExpectation(description: "Handle terminate connection")
        
        socketClient.onClientsTerminated = {
            expectation.fulfill()
        }
        
        let terminateMessage: [String: Any] = ["type": "terminate"]
        
        socketClient.handleResponseMessage(terminateMessage)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testClientsTerminatedDeletesSessionData() {
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567")
        // force keyexchange = true
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        let expectation = XCTestExpectation(description: "Handle terminate connection")
        
        socketClient.onClientsTerminated = {
            expectation.fulfill()
        }
        
        let terminateMessage: [String: Any] = ["type": "terminate"]
        
        socketClient.handleResponseMessage(terminateMessage)
        XCTAssertNil(secureStore.string(for: "session_id"))
        XCTAssertFalse(mockKeyExchange.keysExchanged)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandleResponseMessageData() {
        let keyExchangeMsg = KeyExchangeMessage(type: .ack, pubkey: "0x1234567")
        // force keyexchange = true
        _ = mockKeyExchange.nextMessage(keyExchangeMsg)
        
        let dataMessage: [String: Any] = ["data": ["key": "value"]]
        
        let expectation = XCTestExpectation(description: "Handle response called")
        
        socketClient.handleResponse = { data in
            XCTAssertEqual(data["key"] as? String, "value")
            expectation.fulfill()
        }
        
        socketClient.handleResponseMessage(dataMessage)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandleReceiveKeyExchangeWithPubKeyKeysExchanged() {
        let message: [String: Any] = [
            "message": [
                "type": "key_handshake_SYNACK",
                "pubkey": "0x122345"
            ],
            "id": ""
        ]
        
        socketClient.handleReceiveKeyExchange(message)
        
        XCTAssertTrue(mockKeyExchange.keysExchanged)
    }
    
    func testHandleReceiveKeyExchangeWithoutPubKeyKeysNotExchanged() {
        let message: [String: Any] = [
            "message": [
                "type": "key_handshake_SYNACK",
            ],
            "id": ""
        ]
        
        socketClient.handleReceiveKeyExchange(message)
        
        XCTAssertFalse(mockKeyExchange.keysExchanged)
    }
    
    func testSendMessageSuccessfully() {
        let testMessage = "test message"
        
        socketClient.send(testMessage, encrypt: true)
        
        XCTAssertEqual(mockSocketChannel.lastEmittedEvent, ClientEvent.message)
        XCTAssertEqual((mockSocketChannel.lastEmittedMessage as? SocketMessage<String>)?.message, "encrypted \(testMessage)")
    }
    
    func testSendMessageEncryptionFailure() {
        mockKeyExchange.throwEncryptError = true
        let testMessage = "test message"
        
        socketClient.send(testMessage, encrypt: true)
        
        XCTAssertNil(mockSocketChannel.lastEmittedEvent)
        XCTAssertNil(mockSocketChannel.lastEmittedMessage)
    }
    
    func testHandleReceiveMessagesWithKeyExhangeHandlesKeyExchange() {
        socketClient.handleReceiveMessages()
        
        let keyExchangeMessage: [String: Any] = ["message": ["type": "key_handshake_SYN", "pubkey": ""], "id": ""]
        mockSocketChannel.simulateEvent(ClientEvent.message(on: "mockSessionId"), data: [keyExchangeMessage])
        
        XCTAssertEqual((mockSocketChannel.lastEmittedMessage as? SocketMessage<KeyExchangeMessage>)?.message.type, .synack)
    }
    
    func testHandleReceiveMessagesWithValidMessageNoKeysExchangedDoesNothing() {
        socketClient.handleReceiveMessages()
        
        let validMessage: [String: Any] = ["message": ["type": "data", "content": "test"], "id": "12345"]
        mockSocketChannel.simulateEvent(ClientEvent.message(on: "mockSessionId"), data: [validMessage])
        
        XCTAssertNil(mockSocketChannel.lastEmittedMessage)
    }
    
    func testHandleReceiveMessagesWithValidMessageNoKeysExchangedInitiatesKeyExchange() {
        socketClient.handleReceiveMessages()
        mockKeyExchange.keysExchanged = true
        
        let validMessage: [String: Any] = ["message": ["type": "data", "content": "test"], "id": "12345"]
        mockSocketChannel.simulateEvent(ClientEvent.message(on: "mockSessionId"), data: [validMessage])
        
        XCTAssertEqual((mockSocketChannel.lastEmittedMessage as? SocketMessage<KeyExchangeMessage>)?.message.type, .start)
    }
    
    func testHandleReceiveMessagesWithValidMessageKeysExchanged() {
        mockKeyExchange.keysExchanged = true
        
        socketClient.handleReceiveMessages()
        
        let validMessage: [String: Any] = ["message": "encrypted message", "id": "12345"]
        mockSocketChannel.simulateEvent(ClientEvent.message(on: "mockSessionId"), data: [validMessage])
        
        XCTAssertTrue(mockKeyExchange.decryptCalled)
    }
    
    func testHandleReceiveMessagesWithInvalidMessageInitiatesKeyExchange() {
        mockKeyExchange.keysExchanged = true
        socketClient.handleReceiveMessages()
        
        let invalidMessage: [String: Any] = ["message": ["type": "unknown"], "id": "12345"]
        mockSocketChannel.simulateEvent(ClientEvent.message(on: "mockSessionId"), data: [invalidMessage])
        
        XCTAssertEqual((mockSocketChannel.lastEmittedMessage as? SocketMessage<KeyExchangeMessage>)?.message.type, .start)
    }
    
    func testHandleConnectionConnect() {
        mockKeyExchange.keysExchanged = true
        mockSocketChannel.eventHandlers = [:]
        
        socketClient.handleConnection()
        
        mockSocketChannel.simulateEvent("connect", data: [])
        XCTAssertNotNil(mockSocketChannel.eventHandlers["connect"])
        XCTAssertEqual(mockSocketChannel.lastEmittedEvent, ClientEvent.joinChannel)
    }
    
    func testHandleConnectionError() {
        mockKeyExchange.keysExchanged = true
        mockSocketChannel.eventHandlers = [:]
        
        socketClient.handleConnection()
        
        mockSocketChannel.simulateEvent("error", data: [])
        XCTAssertNotNil(mockSocketChannel.eventHandlers["error"])
    }
    
    func testHandleConnectionClientsConnected() {
        mockKeyExchange.keysExchanged = true
        mockSocketChannel.eventHandlers = [:]
        
        socketClient.handleConnection()

        mockSocketChannel.simulateEvent(ClientEvent.clientsConnected(on: "mockSessionId"), data: [])
        XCTAssertNotNil(mockSocketChannel.eventHandlers[ClientEvent.clientsConnected(on: "mockSessionId")])
    }
    
    func testHandleDisconnection() {
        mockKeyExchange.keysExchanged = true
        mockSocketChannel.eventHandlers = [:]
        
        var trackedEvent: Event?

        socketClient.trackEvent = { event, parameters in
            trackedEvent = event
        }
        
        socketClient.handleDisconnection()

        mockSocketChannel.simulateEvent(ClientEvent.clientDisconnected(on: "mockSessionId"), data: [])
        XCTAssertNotNil(mockSocketChannel.eventHandlers[ClientEvent.clientDisconnected(on: "mockSessionId")])
        XCTAssertEqual(trackedEvent, .disconnected)
    }
}

