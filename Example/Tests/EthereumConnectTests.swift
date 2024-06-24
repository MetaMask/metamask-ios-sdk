//
//  EthereumConnectTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
import Combine
@testable import metamask_ios_sdk

class EthereumConnectTests: XCTestCase {
    
    var mockCommClient: MockCommClient!
    var commClientFactory: CommClientFactory!
    var trackEventMock: ((Event, [String: Any]) -> Void)!
    var ethereum: Ethereum!
    
    override func setUp() {
        super.setUp()
        mockCommClient = MockCommClient()
        commClientFactory = CommClientFactory()
        trackEventMock = { _, _ in }
        EthereumWrapper.shared.ethereum = nil
        SDKWrapper.shared.sdk = nil
        ethereum = Ethereum.shared(
            transport: .socket,
            commClientFactory: commClientFactory,
            trackEvent: trackEventMock)
    }

    override func tearDown() {
        mockCommClient = nil
        trackEventMock = nil
        ethereum = nil
        commClientFactory = nil
        EthereumWrapper.shared.ethereum = nil
        SDKWrapper.shared.sdk = nil
        super.tearDown()
    }

    // Test the singleton instance creation
    func testSingletonInstance() {
        let instance1 = Ethereum.shared(transport: .socket, commClientFactory: commClientFactory, trackEvent: trackEventMock)
        let instance2 = Ethereum.shared(transport: .socket, commClientFactory: commClientFactory, trackEvent: trackEventMock)
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
        ethereum.commClient = mockCommClient
        mockCommClient.connectCalled = false
        
        let publisher = ethereum.connect()
        XCTAssertTrue(mockCommClient.connectCalled)
        
        var cancellable: AnyCancellable?
        cancellable = publisher?.sink(receiveCompletion: { _ in
        }, receiveValue: { value in
            expectation.fulfill()
            cancellable?.cancel()
        })
        
        ethereum.submittedRequests[Ethereum.CONNECTION_ID]?.send(["0x1234567"])
        
        waitForExpectations(timeout: 1.0)
    }
    
    // Test connecting with async/await
    func testConnectAsync() async {
        ethereum.commClient = mockCommClient
        mockCommClient.connectCalled = false
        let expectation = self.expectation(description: "Connect should return a value")
        
        Task {
            let result = await ethereum.connect()
            XCTAssertTrue(self.mockCommClient.connectCalled)
            
            switch result {
            case .success:
                XCTAssert(true)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.ethereum.submittedRequests[Ethereum.CONNECTION_ID]?.send(["0x1234567"])
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testConnectAsyncFailure() async {
        ethereum.commClient = mockCommClient
        mockCommClient.connectCalled = false
        let expectation = self.expectation(description: "Connect should fail")
        
        Task {
            let result = await ethereum.connect()
            XCTAssertTrue(self.mockCommClient.connectCalled)
            
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure:
                expectation.fulfill()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.ethereum.submittedRequests[Ethereum.CONNECTION_ID]?
                .error(RequestError(from: ["message": "Connect failed", "code": "-1"]))
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // Test connect and sign with Combine publisher
    func testConnectAndSignPublisher() {
        let expectation = self.expectation(description: "Connect and sign should return a publisher")
        ethereum.commClient = mockCommClient
        mockCommClient.connectCalled = false
        
        let publisher = ethereum.connectAndSign(message: "Test message")
        XCTAssertTrue(mockCommClient.connectCalled)
        
        var cancellable: AnyCancellable?
        cancellable = publisher?.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                XCTFail("Unexpected completion received")
            case .failure(let error):
                XCTFail("Unexpected error received: \(error)")
            }
            expectation.fulfill()
            cancellable?.cancel()
        }, receiveValue: { _ in
            expectation.fulfill()
            cancellable?.cancel()
        })
        
        guard let submittedRequestId = ethereum.submittedRequests.first(where: { $0.value.method == "metamask_connectSign" })?.key else {
            XCTFail("Could not find submitted request for connectSign")
            return
        }
        
        ethereum.submittedRequests[submittedRequestId]?.send(["0x1234567"])
        
        waitForExpectations(timeout: 2.0)
    }
    
    // Test connect and sign with async/await
    func testConnectAndSignAsync() async {
        mockCommClient.connectCalled = false
        ethereum.commClient = mockCommClient
        
        let expectation = self.expectation(description: "Connect should return a value")
        
        Task {
            let result = await ethereum.connectAndSign(message: "Test message")
            
            XCTAssertTrue(self.mockCommClient.connectCalled)
            switch result {
            case .success:
                XCTAssert(true)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == "metamask_connectSign" })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?.send(["0x1234567"])
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testConnectAndSignAsyncFailure() async {
        mockCommClient.connectCalled = false
        ethereum.commClient = mockCommClient
        
        let expectation = self.expectation(description: "Connect and sign should fail")
        
        Task {
            let result = await ethereum.connectAndSign(message: "Test message")
            
            XCTAssertTrue(self.mockCommClient.connectCalled)
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure:
                expectation.fulfill()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == "metamask_connectSign" })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?
                .error(RequestError(from: ["message": "Connect and sign failed", "code": "-1"]))
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testDisconnect() {
        ethereum.commClient = mockCommClient
        ethereum.disconnect()
        
        XCTAssertFalse(ethereum.connected)
        XCTAssertTrue(mockCommClient.disConnectCalled)
    }
    
    func testClearSession() {
        ethereum.commClient = mockCommClient
        ethereum.clearSession()
        
        XCTAssertFalse(ethereum.connected)
        XCTAssertEqual(ethereum.account, "")
        XCTAssertEqual(ethereum.chainId, "")
        XCTAssertTrue(mockCommClient.disConnectCalled)
    }
    
    func testTerminateConnection() {
        ethereum.terminateConnection()
        
        XCTAssertFalse(ethereum.connected)
        XCTAssertTrue(ethereum.submittedRequests.isEmpty)
    }
    
    func testUpdateMetadata() {
        ethereum.commClient = mockCommClient
        let metadata = AppMetadata(name: "Test App", url: "https://test.app")
        ethereum.updateMetadata(metadata)
        
        XCTAssertEqual(mockCommClient.appMetadata?.name, "Test App")
        XCTAssertEqual(mockCommClient.appMetadata?.url, "https://test.app")
    }
    
    func testConnectWithSocketNonDataParamsPublisher() {
        ethereum.updateTransportLayer(.socket)
        let request = EthereumRequest(method: "eth_signTypedData_v4")
        
        let expectation = self.expectation(description: "Connect with socket non-data params Publisher")
        
        let publisher = ethereum.connectWith(request)
        
        guard let submittedRequestId = ethereum.submittedRequests.first(where: { $0.value.method == "metamask_connectwith" })?.key else {
            XCTFail("Could not find submitted request for connectWith")
            return
        }
        
        var cancellable: AnyCancellable?
        cancellable = publisher?.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                XCTFail("Unexpected completion received")
            case .failure(let error):
                XCTFail("Unexpected error received: \(error)")
            }
            expectation.fulfill()
            cancellable?.cancel()
        }, receiveValue: { _ in
            expectation.fulfill()
            cancellable?.cancel()
        })
        
        ethereum.submittedRequests[submittedRequestId]?.send("0x1234567")
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testConnectWithSocketDataParamsPublisher() {
        ethereum.updateTransportLayer(.socket)
        let dataParams = "testParams".data(using: .utf8)!
        let request = EthereumRequest(method: "eth_signTypedData_v4", params: dataParams)
        let expectation = self.expectation(description: "Connect with socket data params Publisher")
        
        let publisher = ethereum.connectWith(request)
        
        guard let submittedRequestId = ethereum.submittedRequests.first(where: { $0.value.method == "metamask_connectwith" })?.key else {
            XCTFail("Could not find submitted request for connectWith")
            return
        }
        
        var cancellable: AnyCancellable?
        cancellable = publisher?.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                XCTFail("Unexpected completion received")
            case .failure(let error):
                XCTFail("Unexpected error received: \(error)")
            }
            expectation.fulfill()
            cancellable?.cancel()
        }, receiveValue: { _ in
            expectation.fulfill()
            cancellable?.cancel()
        })
        
        ethereum.submittedRequests[submittedRequestId]?.send("0x1234567")
        
        waitForExpectations(timeout: 2.0)
        
    }
    
    func testConnectWithDeeplinkingNonDataParamsPublisher() {
        ethereum.updateTransportLayer(.deeplinking(dappScheme: "testDapp"))
        let request = EthereumRequest(method: "eth_signTypedData_v4", params: "testParams")
        let expectation = self.expectation(description: "Connect with deeplinking non-data params Publisher")
        
        let publisher = ethereum.connectWith(request)
        
        guard let submittedRequestId = ethereum.submittedRequests.first(where: { $0.value.method == "metamask_connectwith" })?.key else {
            XCTFail("Could not find submitted request for connectWith")
            return
        }
        
        var cancellable: AnyCancellable?
        cancellable = publisher?.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                XCTFail("Unexpected completion received")
            case .failure(let error):
                XCTFail("Unexpected error received: \(error)")
            }
            expectation.fulfill()
            cancellable?.cancel()
        }, receiveValue: { _ in
            expectation.fulfill()
            cancellable?.cancel()
        })
        
        ethereum.submittedRequests[submittedRequestId]?.send("0x1234567")
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testConnectWithDeeplinkingDataParamsPublisher() {
        ethereum.updateTransportLayer(.deeplinking(dappScheme: "testDapp"))
        let expectation = self.expectation(description: "Connect with deeplinking data params Publisher")
        
        let dataParams = try! JSONSerialization.data(withJSONObject: ["to": "0x123456"], options: [])
        let request = EthereumRequest(method: "eth_sendTransaction", params: dataParams)
        
        let publisher = ethereum.connectWith(request)
        
        guard let submittedRequestId = ethereum.submittedRequests.first(where: { $0.value.method == "metamask_connectwith" })?.key else {
            XCTFail("Could not find submitted request for connectWith")
            return
        }
        
        var cancellable: AnyCancellable?
        cancellable = publisher?.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                XCTFail("Unexpected completion received")
            case .failure(let error):
                XCTFail("Unexpected error received: \(error)")
            }
            expectation.fulfill()
            cancellable?.cancel()
        }, receiveValue: { _ in
            expectation.fulfill()
            cancellable?.cancel()
        })
        
        ethereum.submittedRequests[submittedRequestId]?.send("0x1234567")
        
        waitForExpectations(timeout: 2.0)
    }
}

