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
    var mockEthereumDelegate: MockEthereumDelegate!
    var trackEventMock: ((Event, [String: Any]) -> Void)!
    var ethereum: Ethereum!
    var mockReadOnlyRPCProvider: MockReadOnlyRPCProvider!
    let infuraApiKey = "testApiKey"
    var cancellables: Set<AnyCancellable>!
    var trackedEvents: [(Event, [String: Any])] = []
    var store: SecureStore!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        store = Keychain(service: "com.example.ethtests")
        mockCommClientFactory = MockCommClientFactory()
        trackEventMock = { [weak self] event, params in
            self?.trackedEvents.append((event, params))
        }
        
        mockNetwork = MockNetwork()
        mockReadOnlyRPCProvider = MockReadOnlyRPCProvider(infuraAPIKey: infuraApiKey, network: mockNetwork)
        mockEthereumDelegate = MockEthereumDelegate()
        EthereumWrapper.shared.ethereum = nil
        SDKWrapper.shared.sdk = nil
        ethereum = Ethereum.shared(
            transport: .socket,
            store: store,
            commClientFactory: mockCommClientFactory,
            readOnlyRPCProvider: mockReadOnlyRPCProvider,
            trackEvent: trackEventMock)
        ethereum.delegate = mockEthereumDelegate
    }
    
    override func tearDown() {
        trackEventMock = nil
        cancellables = nil
        store.deleteAll()
        ethereum = nil
        mockNetwork = nil
        mockEthereumDelegate = nil
        mockReadOnlyRPCProvider = nil
        mockCommClientFactory = nil
        EthereumWrapper.shared.ethereum = nil
        SDKWrapper.shared.sdk = nil
        super.tearDown()
    }
    
    func testSendRequestReadOnlyMethodWithInfuraAPIKey() {
        let expectation = self.expectation(description: "Read only API call")
        let request = EthereumRequest(method: "eth_blockNumber")
        ethereum.chainId = "0x1"
        mockReadOnlyRPCProvider.expectation = expectation
        ethereum.sendRequest(request)
        
        waitForExpectations(timeout: 2.0) { _ in
            XCTAssertTrue(self.mockReadOnlyRPCProvider.sendRequestCalled)
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
        let publisher = ethereum.performRequest(request)
        
        XCTAssertNotNil(publisher)
    }
    
    func testRequestNotConnectedAndEthRequestAccounts() {
        let expectation = self.expectation(description: "Request ethRequestAccounts")
        
        let request = EthereumRequest(method: "eth_requestAccounts")
        let publisher = ethereum.performRequest(request)
        
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
        let publisher = ethereum.performRequest(request)
        
        XCTAssertNotNil(publisher)
        XCTAssertTrue(((ethereum.commClient as? MockCommClient)?.sendMessageCalled) ?? false)
    }
    
    func testRequestWithConnectMethod() {
        let expectation = self.expectation(description: "Request connect method")
        ethereum.updateTransportLayer(.socket)
        
        let request = EthereumRequest(method: "metamask_connectSign")
        let publisher = ethereum.performRequest(request)
        
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
    
    func testSendRequestReadOnlyWithReadOnlyRPCProvider() {
        let expectation = self.expectation(description: "Read-only request with Infura provider")
        let request = EthereumRequest(method: "eth_blockNumber")
        mockReadOnlyRPCProvider.expectation = expectation
        
        ethereum.sendRequest(request)
        
        waitForExpectations(timeout: 2.0) { _ in
            XCTAssertTrue(self.mockReadOnlyRPCProvider.sendRequestCalled)
        }
    }
    
    func testRequestAsyncSingleResult() async {
        let expectation = self.expectation(description: "Request should return result")
        let req = EthereumRequest(method: "personal_sign", params: ["0x12345", "0x1"])
        ethereum.connected = true
        
        Task {
            let result: Result<String, RequestError> = await ethereum.request(req)
            
            switch result {
            case .success:
                XCTAssert(true)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == "personal_sign" })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?.send("0x1234567")
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testRequestAsyncSingleResultFailure() async {
        let expectation = self.expectation(description: "Request should fail")
        let req = EthereumRequest(method: "personal_sign", params: ["0x12345", "0x1"])
        ethereum.connected = true
        
        Task {
            let result: Result<String, RequestError> = await ethereum.request(req)
            
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure:
                expectation.fulfill()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == "personal_sign" })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?
                .error(RequestError(from: ["message": "Connect failed", "code": "-1"]))
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testRequestAsyncCollectionResult() async {
        let expectation = self.expectation(description: "Request should return result")
        let request1 = EthereumRequest(method: "personal_sign", params: [String: String]())
        let request2 = EthereumRequest(method: "personal_sign", params: [String: String]())
        let requests = [request1, request2]
        let batchRequest = EthereumRequest(
            method: EthereumMethod.metamaskBatch.rawValue,
            params: requests)
        
        ethereum.connected = true
        
        Task {
            let result: Result<[String], RequestError> = await ethereum.request(batchRequest)
            
            switch result {
            case .success:
                XCTAssert(true)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == "metamask_batch" })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?.send(["0x1234567", "0x7654321"])
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testRequestAsyncCollectionResultFailure() async {
        let expectation = self.expectation(description: "Request should fail")
        let request1 = EthereumRequest(method: "personal_sign", params: [String: String]())
        let request2 = EthereumRequest(method: "personal_sign", params: [String: String]())
        let requests = [request1, request2]
        let batchRequest = EthereumRequest(
            method: EthereumMethod.metamaskBatch.rawValue,
            params: requests)
        
        ethereum.connected = true
        
        Task {
            let result: Result<[String], RequestError> = await ethereum.request(batchRequest)
            
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure:
                expectation.fulfill()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == "metamask_batch" })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?
                .error(RequestError(from: ["message": "Connect failed", "code": "-1"]))
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testUpdateTransportWithSocket() {
        ethereum.updateTransportLayer(.socket)
        
        XCTAssertTrue(ethereum.commClient is MockSocketCommClient)
        XCTAssertTrue(ethereum.transport == .socket)
    }
    
    func testTransportWithDeeplinking() {
        ethereum.updateTransportLayer(.deeplinking(dappScheme: "testDapp"))
        
        XCTAssertTrue(ethereum.commClient is MockDeeplinkCommClient)
        XCTAssertTrue(ethereum.transport == .deeplinking(dappScheme: "testDapp"))
    }
    
    // MARK: Requests
    
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
    
    func testDeeplinkingSendRequest() {
        let params = [
            "challenge": "0x506c65617365207369676e2074686973206d65737361676520746f20636f6e6669726d20796f7572206964656e746974792e",
            "address": "0x4B0897b0513FdBeEc7C469D9aF4fA6C0752aBea7"
        ]
        
        let request = EthereumRequest(method: "personal_sign", params: params)
        ethereum.updateTransportLayer(.deeplinking(dappScheme: "testDapp"))
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
    
    // MARK: Responses
    
    func testReceiveResponseWithError() {
        let requestId = "1"
        let request = SubmittedRequest(method: "eth_requestAccounts")
        ethereum.submittedRequests[requestId] = request

        let errorData: [String: Any] = [
            "error": ["message": "User rejected request", "code": -32000],
            "accounts": ["0x1234"],
            "chainId": "0x1"
        ]

        ethereum.receiveResponse(errorData, id: requestId)

        XCTAssertTrue(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertTrue(mockEthereumDelegate.accountChangedCalled)
        XCTAssertNil(ethereum.submittedRequests[requestId])
    }
    
    func testReceiveResponseWithResultOnly() {
        let requestId = "2"
        let request = SubmittedRequest(method: "eth_chainId")
        ethereum.submittedRequests[requestId] = request

        let resultData: [String: Any] = [
            "result": "0x1"
        ]

        ethereum.receiveResponse(resultData, id: requestId)

        XCTAssertTrue(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertNil(ethereum.submittedRequests[requestId])
    }
    
    func testReceiveResponseWithoutErrorAndWithResult() {
        let requestId = "3"
        let request = SubmittedRequest(method: "eth_requestAccounts")
        ethereum.submittedRequests[requestId] = request

        let resultData: [String: Any] = [
            "result": ["0x1234"]
        ]

        ethereum.receiveResponse(resultData, id: requestId)

        XCTAssertTrue(mockEthereumDelegate.accountChangedCalled)
        XCTAssertNil(ethereum.submittedRequests[requestId])
    }
    
    func testReceiveResponseWithoutErrorAndWithEmptyResult() {
        let requestId = "4"
        let request = SubmittedRequest(method: "eth_requestAccounts")
        ethereum.submittedRequests[requestId] = request

        let resultData: [String: Any] = [:]

        ethereum.receiveResponse(resultData, id: requestId)

        XCTAssertFalse(mockEthereumDelegate.accountChangedCalled)
        XCTAssertFalse(mockEthereumDelegate.chainIdChangedCalled)
    }
    
    func testReadOnlyMethodReceiveResponseWithResult() {
        let requestId = "123"
        let request = SubmittedRequest(method: "eth_getTransactionCount")
        let expectation = self.expectation(description: "Result received")
        ethereum.submittedRequests[requestId] = request
        
        let resultData: [String: Any] = ["result": "0x1a"]
        
        request.publisher?.sink(receiveCompletion: { _ in },
                                receiveValue: { result in
            XCTAssertEqual(result as? String, "0x1a")
            expectation.fulfill()
        }).store(in: &cancellables)

        ethereum.receiveResponse(resultData, id: requestId)
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testReadOnlyMethodReceiveResponseWithoutResult() {
        let requestId = "123"
        let request = SubmittedRequest(method: "eth_getTransactionCount")
        let expectation = self.expectation(description: "Result received")
        ethereum.submittedRequests[requestId] = request
        
        let resultData: [String: Any] = [:]
        
        request.publisher?.sink(receiveCompletion: { _ in },
                                receiveValue: { result in
            XCTAssertNotNil(result)
            expectation.fulfill()
        }).store(in: &cancellables)

        ethereum.receiveResponse(resultData, id: requestId)
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testGetProviderStateResult() {
        let requestId = "246"
        let request = SubmittedRequest(method: "metamask_getProviderState")
        let expectation = self.expectation(description: "Result received")
        ethereum.submittedRequests[requestId] = request
        
        let resultData: [String: Any] = ["result": [
            "accounts": ["0x1234"],
            "chainId": "0x1"
            ]
        ]
        
        request.publisher?.sink(receiveCompletion: { _ in },
                                receiveValue: { result in
            XCTAssertTrue(self.mockEthereumDelegate.chainIdChangedCalled)
            XCTAssertTrue(self.mockEthereumDelegate.accountChangedCalled)
            expectation.fulfill()
        }).store(in: &cancellables)

        ethereum.receiveResponse(resultData, id: requestId)
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDefaultCaseResult() {
        let requestId = "246"
        let request = SubmittedRequest(method: "personal_sign")
        let expectation = self.expectation(description: "Result received")
        ethereum.submittedRequests[requestId] = request
        
        let resultData: [String: Any] = ["result": "0xdsgfyfyewveffvejj"
        ]
        
        request.publisher?.sink(receiveCompletion: { _ in },
                                receiveValue: { result in
            XCTAssertEqual(result as? String, "0xdsgfyfyewveffvejj")
            expectation.fulfill()
        }).store(in: &cancellables)

        ethereum.receiveResponse(resultData, id: requestId)
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSignTypedDatV4Result() {
        let requestId = "246"
        let request = SubmittedRequest(method: "eth_signTypedData_v4")
        let expectation = self.expectation(description: "Result received")
        ethereum.submittedRequests[requestId] = request
        
        let resultData: [String: Any] = ["result": "0xdjbsddy3y3behfbvvf"]
        
        request.publisher?.sink(receiveCompletion: { _ in },
                                receiveValue: { result in
            XCTAssertEqual(result as? String, "0xdjbsddy3y3behfbvvf")
            expectation.fulfill()
        }).store(in: &cancellables)

        ethereum.receiveResponse(resultData, id: requestId)
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testReceiveResponseWithMetamaskBatch() {
        let requestId = Ethereum.BATCH_CONNECTION_ID
        let request = SubmittedRequest(method: "metamask_batch")
        ethereum.submittedRequests[requestId] = request
        let ethereumMainnet = "0x1"
        let accounts = ["0x1234"]

        let resultData: [String: Any] = [
            "result": [["0x1234"], ethereumMainnet]
        ]

        ethereum.receiveResponse(resultData, id: requestId)

        XCTAssertTrue(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.chainId, ethereumMainnet)
        XCTAssertTrue(mockEthereumDelegate.accountChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.account, accounts.first)
    }
    
    func testReceiveDataResponseWithMetamaskBatch() {
        let requestId = Ethereum.BATCH_CONNECTION_ID
        let request = SubmittedRequest(method: "metamask_batch")
        ethereum.submittedRequests[requestId] = request
        let polygonChainId = "0x89"
        let accounts = ["0x1234"]

        let message: [String: Any] = [
            "data": [
                "id": requestId,
                "result": ["0xf9990f422f9a", "0x8904d14b2c67b3988ca27"],
                "chainId": polygonChainId,
                "accounts": accounts
            ]
        ]
        
        let data = message["data"] as? [String: Any] ?? [:]

        ethereum.handleMessage(data)

        XCTAssertTrue(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.chainId, polygonChainId)
        XCTAssertTrue(mockEthereumDelegate.accountChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.account, accounts.first)
    }
    
    // MARK: Events
    func testReceiveEventWithError() {
        let event: [String: Any] = [
            "error": ["message": "User rejected request", "code": 4001]
        ]

        ethereum.receiveEvent(event)
        
        let trackedEvent = trackedEvents.first?.0
        let params = trackedEvents.first?.1

        XCTAssertEqual(trackedEvents.count, 1)
        
        XCTAssertEqual(trackedEvent, .connectionRejected)
        XCTAssertEqual(params?.isEmpty, true)
    }
    
    func testReceiveEventWithChainId() {
        let event: [String: Any] = [
            "chainId": "0x1"
        ]

        ethereum.receiveEvent(event)

        XCTAssertTrue(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.chainId, "0x1")
    }
    
    func testChainIdIsUpdated() {
        let event: [String: Any] = [
            "chainId": "0x1"
        ]

        XCTAssertTrue(ethereum.chainId.isEmpty)
        ethereum.receiveEvent(event)

        
        XCTAssertTrue(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.chainId, "0x1")
        XCTAssertEqual(ethereum.chainId, "0x1")
    }
    
    func testReceiveEventWithAccounts() {
        let event: [String: Any] = [
            "accounts": ["0x1234"]
        ]

        ethereum.receiveEvent(event)

        XCTAssertTrue(mockEthereumDelegate.accountChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.account, "0x1234")
    }
    
    func testAccountsUpdated() {
        let event: [String: Any] = [
            "accounts": ["0x1234"]
        ]

        XCTAssertTrue(ethereum.account.isEmpty)
        ethereum.receiveEvent(event)

        XCTAssertTrue(mockEthereumDelegate.accountChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.account, "0x1234")
        XCTAssertEqual(ethereum.account, "0x1234")
    }
    
    func testReceiveEventWithMetaMaskAccountsChanged() {
        let event: [String: Any] = [
            "method": "metamask_accountsChanged",
            "params": ["0x1234"]
        ]

        ethereum.receiveEvent(event)

        XCTAssertTrue(mockEthereumDelegate.accountChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.account, "0x1234")
    }
    
    func testReceiveEventWithMetaMaskChainChanged() {
        let event: [String: Any] = [
            "method": "metamask_chainChanged",
            "params": ["chainId": "0x1"]
        ]

        ethereum.receiveEvent(event)

        XCTAssertTrue(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertEqual(mockEthereumDelegate.chainId, "0x1")
    }
    
    
    func testReceiveEventUnhandledCase() {
        let event: [String: Any] = [
            "method": "unhandled_method"
        ]

        ethereum.receiveEvent(event)

        XCTAssertFalse(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertFalse(mockEthereumDelegate.accountChangedCalled)
    }
    
    func testHandleMessageWithInt64Id() {
        let message: [String: Any] = [
            "id": Int64(123),
            "method": "metamask_chainChanged",
            "params": ["chainId": "0x1"]
        ]
        
        ethereum.handleMessage(message)
        
        XCTAssertFalse(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertFalse(mockEthereumDelegate.accountChangedCalled)
    }
    
    func testHandleMessageWithString() {
        let message: [String: Any] = [
            "id": "123",
            "method": "metamask_chainChanged",
            "params": ["chainId": "0x1"]
        ]
        
        ethereum.handleMessage(message)
        
        XCTAssertFalse(mockEthereumDelegate.chainIdChangedCalled)
        XCTAssertFalse(mockEthereumDelegate.accountChangedCalled)
    }
    
    func testReadOnlyRPCProvider() {
        XCTAssertTrue(ethereum.readOnlyRPCProvider is MockReadOnlyRPCProvider)
        ethereum.readOnlyRPCProvider = nil
        XCTAssertNil(ethereum.readOnlyRPCProvider)
    }
}
