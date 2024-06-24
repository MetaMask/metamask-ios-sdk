//
//  EthereumTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
import Combine
@testable import metamask_ios_sdk

class EthereumTests: XCTestCase {
    var mockCommClientFactory: MockCommClientFactory!
    var mockNetwork: MockNetwork!
    var trackEventMock: ((Event, [String: Any]) -> Void)!
    var ethereum: Ethereum!
    var mockInfuraProvider: MockInfuraProvider!
    let infuraApiKey = "testApiKey"
    
    override func setUp() {
        super.setUp()
        mockCommClientFactory = MockCommClientFactory()
        trackEventMock = { _, _ in }
        
        mockNetwork = MockNetwork()
        mockInfuraProvider = MockInfuraProvider(infuraAPIKey: infuraApiKey, network: mockNetwork)
        EthereumWrapper.shared.ethereum = nil
        SDKWrapper.shared.sdk = nil
        ethereum = Ethereum.shared(
            transport: .socket,
            commClientFactory: mockCommClientFactory,
            infuraProvider: mockInfuraProvider,
            trackEvent: trackEventMock)
    }
    
    override func tearDown() {
        trackEventMock = nil
        ethereum = nil
        mockNetwork = nil
        mockInfuraProvider = nil
        mockCommClientFactory = nil
        EthereumWrapper.shared.ethereum = nil
        SDKWrapper.shared.sdk = nil
        super.tearDown()
    }
    
    func testSendRequestReadOnlyMethodWithInfuraAPIKey() {
        let expectation = self.expectation(description: "Read only API call")
        let request = EthereumRequest(method: "eth_blockNumber")
        ethereum.chainId = "0x1"
        mockInfuraProvider.expectation = expectation
        ethereum.sendRequest(request)
        
        waitForExpectations(timeout: 2.0) { _ in
            XCTAssertTrue(self.mockInfuraProvider.sendRequestCalled)
        }
    }
    
    func testSendRequestNonReadOnlyMethod() {
        let expectation = self.expectation(description: "Non Read-only API call")
        let request = EthereumRequest(method: "eth_sendTransaction")
        ethereum.chainId = "0x1"
        (ethereum.commClient as? MockCommClient)?.expectation = expectation
        ethereum.sendRequest(request)
        
        waitForExpectations(timeout: 2.0) { _ in
            XCTAssertTrue((((self.ethereum.commClient as? MockCommClient)?.sendMessageCalled) ?? false))
        }
    }
    
    func testRequestReturnsPublisher() {
        let request = EthereumRequest(method: "eth_call")
        let publisher = ethereum.request(request)
        
        XCTAssertNotNil(publisher)
    }
    
    func testRequestNotConnectedAndEthRequestAccounts() {
        let expectation = self.expectation(description: "Request ethRequestAccounts")
        
        let request = EthereumRequest(method: "eth_requestAccounts")
        let publisher = ethereum.request(request)
        
        XCTAssertTrue((((self.ethereum.commClient as? MockCommClient)?.connectCalled) ?? false))
        XCTAssertTrue(ethereum.connected)
        
        var cancellable: AnyCancellable?
        cancellable = publisher?.sink(receiveCompletion: { _ in }, receiveValue: { value in
            XCTAssertEqual(value as? [String], ["0x12345"])
            expectation.fulfill()
            cancellable?.cancel()
        })
        
        guard let submittedRequestId = ethereum.submittedRequests.first(where: { $0.value.method == "eth_requestAccounts" })?.key else {
            XCTFail("Could not find submitted request for eth_requestAccounts")
            return
        }
        
        ethereum.submittedRequests[submittedRequestId]?.send(["0x12345"])
        waitForExpectations(timeout: 2.0)
    }
    
    func testRequestConnected() {
        ethereum.connected = true
        let request = EthereumRequest(method: "eth_sendTransaction")
        let publisher = ethereum.request(request)
        
        XCTAssertNotNil(publisher)
        XCTAssertTrue(((ethereum.commClient as? MockCommClient)?.sendMessageCalled) ?? false)
    }
    
    func testRequestNotConnectedButConnectMethod() {
        let expectation = self.expectation(description: "Request connect method")
        
        let request = EthereumRequest(method: "metamask_connectSign")
        let publisher = ethereum.request(request)
        
        XCTAssertTrue(((self.ethereum.commClient as? MockCommClient)?.connectCalled) ?? false)
        XCTAssertTrue(ethereum.connected)
        XCTAssertTrue(((self.ethereum.commClient as? MockCommClient)?.addRequestCalled) ?? false)
        
        var cancellable: AnyCancellable?
        cancellable = publisher?.sink(receiveCompletion: { _ in }, receiveValue: { value in
            XCTAssertEqual(value as? [String], ["0x12345"])
            expectation.fulfill()
            cancellable?.cancel()
        })
        
        (ethereum.commClient as? MockCommClient)?.addRequestJob?()
        
        guard let submittedRequestId = ethereum.submittedRequests.first(where: { $0.value.method == "metamask_connectSign" })?.key else {
            XCTFail("Could not find submitted request for personal_sign")
            return
        }
        
        ethereum.submittedRequests[submittedRequestId]?.send(["0x12345"])
        waitForExpectations(timeout: 2.0)
    }
    
    func testSendRequestReadOnlyWithInfuraProvider() {
        let expectation = self.expectation(description: "Read-only request with Infura provider")
        let request = EthereumRequest(method: "eth_blockNumber")
        mockInfuraProvider.expectation = expectation
        
        ethereum.sendRequest(request)
        
        waitForExpectations(timeout: 2.0) { _ in
            XCTAssertTrue(self.mockInfuraProvider.sendRequestCalled)
        }
    }
    
    func testUpdateTransportWithSocket() {
        ethereum.updateTransportLayer(.socket)
        
        XCTAssertTrue(ethereum.commClient is MockSocketCommClient)
    }
    
    func testTransportWithDeeplinking() {
        ethereum.updateTransportLayer(.deeplinking(dappScheme: "testDapp"))
        
        XCTAssertTrue(ethereum.commClient is MockDeeplinkCommClient)
    }
    
    func testSendRequest() {
        let request = EthereumRequest(method: "personal_sign")
        ethereum.sendRequest(request)
        
        XCTAssertTrue(((self.ethereum.commClient as? MockCommClient)?.sendMessageCalled) ?? false)
    }
    
    func testSocketSendRequestWithData() {
        guard let params: Data = "{\"chainId\":\"0x1\"}".data(using: .utf8) else {
            XCTFail("Could not obtain params  data")
            return
        }
        
        let request = EthereumRequest(method: "personal_sign", params: params)
        ethereum.updateTransportLayer(.socket)
        ethereum.sendRequest(request)
        
        XCTAssertTrue(((self.ethereum.commClient as? MockCommClient)?.sendMessageCalled) ?? false)
    }
    
    func testDeeplinkingSendRequestWithData() {
        guard let params: Data = "{\"chainId\":\"0x1\"}".data(using: .utf8) else {
            XCTFail("Could not obtain params  data")
            return
        }
        
        let request = EthereumRequest(method: "personal_sign", params: params)
        ethereum.updateTransportLayer(.deeplinking(dappScheme: "testDapp"))
        ethereum.sendRequest(request)
        
        XCTAssertTrue(((self.ethereum.commClient as? MockCommClient)?.sendMessageCalled) ?? false)
    }
    
    func testBatchRequest() async {
        let expectation = self.expectation(description: "Batch request with valid data params")

        let request1 = EthereumRequest(method: "personal_sign", params: [String: String]())
        let request2 = EthereumRequest(method: "personal_sign", params: [String: String]())
        let requests = [request1, request2]

        ethereum.connected = true
        
        Task {
            let result = await ethereum.batchRequest(requests)
            
            switch result {
            case .success(let responses):
                XCTAssertEqual(responses.count, 2)
                XCTAssertEqual(responses, ["response1", "response2"])
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, but got error: \(error)")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == "metamask_batch" })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?.send(["response1", "response2"])
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testBatchRequestWithDataParams() async {
        let expectation = self.expectation(description: "Batch request with valid data params")

        guard let transactionData = "{\"data\":\"0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675\",\"from\": \"0x0000000000000000000000000000000000000000\",\"gas\": \"0x76c0\",\"gasPrice\": \"0x9184e72a000\",\"to\": \"0xd46e8dd67c5d32be8058bb8eb970870f07244567\",\"value\": \"0x9184e72a\"}".data(using: .utf8) else {
            XCTFail("Could not obtain transaction data")
            return
        }
        let transactionRequest1 = EthereumRequest(method: "eth_sendTransaction", params: [transactionData])
        let transactionReques2 = EthereumRequest(method: "eth_sendTransaction", params: [transactionData])
        let requests = [transactionRequest1, transactionReques2]

        ethereum.connected = true
        
        Task {
            let result = await ethereum.batchRequest(requests)
            
            switch result {
            case .success(let responses):
                XCTAssertEqual(responses.count, 2)
                XCTAssertEqual(responses, ["result1", "result2"])
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, but got error: \(error)")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == "metamask_batch" })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?.send(["result1", "result2"])
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testSendRequestRequiresAuthorizationWithSocket() {
        let request = EthereumRequest(method: "eth_sendTransaction")
        ethereum.connected = true
        
        ethereum.sendRequest(request)
        
        XCTAssertTrue((ethereum.commClient as? MockCommClient)?.requestAuthorisationCalled ?? false)
    }
}
