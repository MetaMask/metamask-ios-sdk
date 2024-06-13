//
//  EthereumTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
import Combine
@testable import metamask_ios_sdk

class EthereumTests: XCTestCase {
    
    var mockCommClient: MockCommClient!
    var trackEventMock: ((Event, [String: Any]) -> Void)!
    var ethereum: Ethereum!
    
    override func setUp() {
        super.setUp()
        mockCommClient = MockCommClient()
        trackEventMock = { _, _ in }
        ethereum = Ethereum(commClient: mockCommClient, track: trackEventMock)
    }

    override func tearDown() {
        mockCommClient = nil
        trackEventMock = nil
        ethereum = nil
        super.tearDown()
    }

    // Test the singleton instance creation
    func testSingletonInstance() {
        let instance1 = Ethereum.shared(commClient: mockCommClient, trackEvent: trackEventMock)
        let instance2 = Ethereum.shared(commClient: mockCommClient, trackEvent: trackEventMock)
        XCTAssert(instance1 === instance2)
    }
    
    func testUpdateTransportLayerToSocket() {
        let updatedEthereum = ethereum.updateTransportLayer(.socket)
        XCTAssertEqual(updatedEthereum.transport, .socket)
        XCTAssertTrue(ethereum.commClient is SocketClient)
    }
    
    func testUpdateTransportLayerToDeeplink() {
        let updatedEthereum = ethereum.updateTransportLayer(.deeplinking(dappScheme: "testdapp"))
        XCTAssertEqual(updatedEthereum.transport, .deeplinking(dappScheme: "testdapp"))
        XCTAssertTrue(ethereum.commClient is DeeplinkClient)
    }

    // Test connecting with Combine publisher
    func testConnectPublisher() {
        let expectation = self.expectation(description: "Connect should return a publisher")
        mockCommClient.connectCalled = false
        
        let publisher = ethereum.connect()
        XCTAssertTrue(mockCommClient.connectCalled)
        
        var cancellable: AnyCancellable?
        cancellable = publisher?.sink(receiveCompletion: { _ in
            expectation.fulfill()
            cancellable?.cancel()
        }, receiveValue: { _ in })
        
        waitForExpectations(timeout: 2.0)
    }
    
//    // Test connecting with async/await
//    func testConnectAsync() async {
//        mockCommClient.connectCalled = false
//        let result = await ethereum.connect()
//        XCTAssertTrue(mockCommClient.connectCalled)
//        switch result {
//        case .success:
//            XCTAssert(true)
//        case .failure:
//            XCTFail("Expected success but got failure")
//        }
//    }
//
//    // Test connect and sign with Combine publisher
//    func testConnectAndSignPublisher() {
//        let expectation = self.expectation(description: "Connect and sign should return a publisher")
//        mockCommClient.connectCalled = false
//        
//        let publisher = ethereum.connectAndSign(message: "Test message")
//        XCTAssertTrue(mockCommClient.connectCalled)
//        
//        var cancellable: AnyCancellable?
//        cancellable = publisher?.sink(receiveCompletion: { _ in
//            expectation.fulfill()
//            cancellable?.cancel()
//        }, receiveValue: { _ in })
//        
//        waitForExpectations(timeout: 2.0)
//    }
//    
//    // Test connect and sign with async/await
//    func testConnectAndSignAsync() async {
//        mockCommClient.connectCalled = false
//        let result = await ethereum.connectAndSign(message: "Test message")
//        XCTAssertTrue(mockCommClient.connectCalled)
//        switch result {
//        case .success:
//            XCTAssert(true)
//        case .failure:
//            XCTFail("Expected success but got failure")
//        }
//    }
//    
//    // Test disconnect
//    func testDisconnect() {
//        ethereum.disconnect()
//        XCTAssertFalse(ethereum.connected)
//    }
//    
//    // Test clear session
//    func testClearSession() {
//        ethereum.clearSession()
//        XCTAssertFalse(ethereum.connected)
//        XCTAssertEqual(ethereum.account, "")
//        XCTAssertEqual(ethereum.chainId, "")
//    }
//    
//    // Test terminate connection
//    func testTerminateConnection() {
//        ethereum.terminateConnection()
//        XCTAssertFalse(ethereum.connected)
//    }
//    
//    // Test update metadata
//    func testUpdateMetadata() {
//        let metadata = AppMetadata(name: "Test App", url: "https://test.app")
//        ethereum.updateMetadata(metadata)
//        XCTAssertEqual(mockCommClient.appMetadata?.name, "Test App")
//        XCTAssertEqual(mockCommClient.appMetadata?.url, "https://test.app")
//    }
//    
//    // Test handling message
//    func testHandleMessage() {
//        let message: [String: Any] = ["id": "1", "result": "Success"]
//        ethereum.handleMessage(message)
//        // Add assertions based on your handling logic
//    }
//    
//    // Test sending request
//    func testSendRequest() {
//        let request = EthereumRequest<String>(method: .ethAccounts)
//        ethereum.sendRequest(request)
//        // Add assertions based on your sending logic
//    }
}
