//
//  EthereumConvenienceMethodsTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
import Combine
@testable import metamask_ios_sdk

class EthereumConvenienceMethodsTests: XCTestCase {
    var mockCommClientFactory: MockCommClientFactory!
    var mockNetwork: MockNetwork!
    var mockEthereumDelegate: MockEthereumDelegate!
    var trackEventMock: ((Event, [String: Any]) -> Void)!
    var ethereum: Ethereum!
    var mockInfuraProvider: MockInfuraProvider!
    let infuraApiKey = "testApiKey"
    var trackedEvents: [(Event, [String: Any])] = []
    
    override func setUp() {
        super.setUp()
        mockCommClientFactory = MockCommClientFactory()
        trackEventMock = { [weak self] event, params in
            self?.trackedEvents.append((event, params))
        }
        
        mockNetwork = MockNetwork()
        mockInfuraProvider = MockInfuraProvider(infuraAPIKey: infuraApiKey, network: mockNetwork)
        mockEthereumDelegate = MockEthereumDelegate()
        EthereumWrapper.shared.ethereum = nil
        SDKWrapper.shared.sdk = nil
        ethereum = Ethereum.shared(
            transport: .socket,
            commClientFactory: mockCommClientFactory,
            infuraProvider: mockInfuraProvider,
            trackEvent: trackEventMock)
        ethereum.delegate = mockEthereumDelegate
    }
    
    override func tearDown() {
        trackEventMock = nil
        ethereum = nil
        mockNetwork = nil
        mockEthereumDelegate = nil
        mockInfuraProvider = nil
        mockCommClientFactory = nil
        EthereumWrapper.shared.ethereum = nil
        SDKWrapper.shared.sdk = nil
        super.tearDown()
    }
   
    func testGetChainId() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let chainId = "0x1"
        
        let expectation = self.expectation(description: "Request should return chainId")
        performSuccessfulTask(
            ethereum.getChainId,
            expectedValue: chainId,
            expectation: expectation)
        sendResultAndAwait(chainId, method: .ethChainId)
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testGetEthAccounts() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let accounts = ["0x1234"]
         
         let expectation = self.expectation(description: "Request should return accounts")
         performSuccessfulTaskCollectionResult(
            ethereum.getEthAccounts,
            expectedValue: accounts,
            expectation: expectation)
        sendResultAndAwait(accounts, method: .ethAccounts)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testGetEthGasPrice() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let balance = "0x1000"

        let expectation = self.expectation(description: "Request should return gas price")
        performSuccessfulTask(ethereum.getEthGasPrice,
                              expectedValue: balance,
                              expectation: expectation)
        sendResultAndAwait(balance, method: .ethGasPrice)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testGetEthBalance() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let balance = "0x1000"

        let expectation = self.expectation(description: "Request should return balance")
        performSuccessfulTask({
            await self.ethereum.getEthBalance(address: "0x1234", block: "latest")
        }, expectedValue: balance, expectation: expectation)
        sendResultAndAwait(balance, method: .ethGetBalance)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testGetEthBlockNumber() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let blockNumber = "0x10"

        let expectation = self.expectation(description: "Request should return block number")
        performSuccessfulTask({
            await self.ethereum.getEthBlockNumber()
        }, expectedValue: blockNumber, expectation: expectation)
        sendResultAndAwait(blockNumber, method: .ethBlockNumber)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testGetEthEstimateGas() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let gasEstimate = "0x5208"

        let expectation = self.expectation(description: "Request should return gas estimate")
        performSuccessfulTask({
            await self.ethereum.getEthEstimateGas()
        }, expectedValue: gasEstimate, expectation: expectation)
        sendResultAndAwait(gasEstimate, method: .ethEstimateGas)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testGetWeb3ClientVersion() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let web3Version = "Geth/v1.8.23-stable"

        let expectation = self.expectation(description: "Request should return web3 version")
        performSuccessfulTask({
            await self.ethereum.getWeb3ClientVersion()
        }, expectedValue: web3Version, expectation: expectation)
        sendResultAndAwait(web3Version, method: .web3ClientVersion)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testPersonalSign() async {
        ethereum.connected = true
        let signResult = "0xabc123"

        let expectation = self.expectation(description: "Request should return personal sign result")
        performSuccessfulTask({
            await self.ethereum.personalSign(message: "Hello", address: "0x1234")
        }, expectedValue: signResult, expectation: expectation)
        sendResultAndAwait(signResult, method: .personalSign)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testSignTypedDataV4() async {
        ethereum.connected = true
        let signResult = "0xabc123"

        let expectation = self.expectation(description: "Request should return sign result")
        performSuccessfulTask({
            await self.ethereum.signTypedDataV4(typedData: "typedData", address: "0x1234")
        }, expectedValue: signResult, expectation: expectation)
        sendResultAndAwait(signResult, method: .ethSignTypedDataV4)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testSendTransaction() async {
        ethereum.connected = true
        let transactionHash = "0x789abc"

        let expectation = self.expectation(description: "Request should return transaction hash result")
        performSuccessfulTask({
            await self.ethereum.sendTransaction(from: "0x1234", to: "0x5678", amount: "0x10")
        }, expectedValue: transactionHash, expectation: expectation)
        sendResultAndAwait(transactionHash, method: .ethSendTransaction)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testSendRawTransaction() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let transactionHash = "0x345678"

        let expectation = self.expectation(description: "Request should return transaction hash result")
        performSuccessfulTask({
            await self.ethereum.sendRawTransaction(signedTransaction: "signedTx")
        }, expectedValue: transactionHash, expectation: expectation)
        sendResultAndAwait(transactionHash, method: .ethSendRawTransaction)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testGetBlockTransactionCountByNumber() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let transactionCount = "0x20"

        let expectation = self.expectation(description: "Request should return transaction count")
        performSuccessfulTask({
            await self.ethereum.getBlockTransactionCountByNumber(blockNumber: "0x10")
        }, expectedValue: transactionCount, expectation: expectation)
        sendResultAndAwait(transactionCount, method: .ethGetBlockTransactionCountByNumber)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testGetBlockTransactionCountByHash() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let transactionCount = "0x30"

        let expectation = self.expectation(description: "Request should return transaction count")
        performSuccessfulTask({
            await self.ethereum.getBlockTransactionCountByHash(blockHash: "0xabcdef")
        }, expectedValue: transactionCount, expectation: expectation)
        sendResultAndAwait(transactionCount, method: .ethGetBlockTransactionCountByHash)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testGetTransactionCount() async {
        ethereum.connected = true
        ethereum.infuraProvider = nil
        let transactionCount = "0x40"

        let expectation = self.expectation(description: "Request should return transaction count")
        performSuccessfulTask({
            await self.ethereum.getTransactionCount(address: "0x1234", tagOrblockNumber: "latest")
        }, expectedValue: transactionCount, expectation: expectation)
        sendResultAndAwait(transactionCount, method: .ethGetTransactionCount)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testAddEthereumChain() async {
        ethereum.connected = true
        let chainId = "0x1"
        let nativeCurrency = NativeCurrency(name: "Ether", symbol: "ETH", decimals: 18)


        let expectation = self.expectation(description: "Request should return new chainId")
        performSuccessfulTask({
            await self.ethereum.addEthereumChain(
                chainId: chainId,
                chainName: "Mainnet",
                rpcUrls: ["https://mainnet.infura.io/v3/"],
                iconUrls: ["https://example.com/icon.png"],
                blockExplorerUrls: ["https://etherscan.io"],
                nativeCurrency: nativeCurrency
            )
        }, expectedValue: chainId, expectation: expectation)
        sendResultAndAwait(chainId, method: .addEthereumChain)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testSwitchEthereumChain() async {
        ethereum.connected = true
        let chainId = "0x1"

        let expectation = self.expectation(description: "Request should return new chainId")
        performSuccessfulTask({
            await self.ethereum.switchEthereumChain(chainId: chainId)
        }, expectedValue: chainId, expectation: expectation)
        sendResultAndAwait(chainId, method: .switchEthereumChain)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func performSuccessfulTask(_ task: @escaping () async -> Result<String, RequestError>,
                               expectedValue: String,
                               expectation: XCTestExpectation) {
        Task {
            let result: Result<String, RequestError> = await task()
            
            switch result {
            case .success (let value):
                XCTAssertEqual(value, expectedValue)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }

    func performSuccessfulTaskCollectionResult(_ task: @escaping () async -> Result<[String], RequestError>,
                                               expectedValue: [String],
                                               expectation: XCTestExpectation) {
        Task {
            let result: Result<[String], RequestError> = await task()
            
            switch result {
            case .success (let value):
                XCTAssertEqual(value, expectedValue)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }
    
    func performFailedTask(_ task: @escaping () async -> Result<String,
                           RequestError>, expectation: XCTestExpectation) {
        Task {
            let result: Result<String, RequestError> = await task()
            
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure:
                expectation.fulfill()
            }
        }
    }

    func sendResultAndAwait(_ result: Any, method: EthereumMethod) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == method.rawValue })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?.send(result)
        }
    }

    func sendErrorAndAwait(method: EthereumMethod) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let submittedRequestId: String = self?.ethereum.submittedRequests.first(where: { $0.value.method == method.rawValue })?.key as? String ?? ""
            self?.ethereum.submittedRequests[submittedRequestId]?
                .error(RequestError(from: ["message": "Connect failed", "code": "-1"]))
        }
    }
}
