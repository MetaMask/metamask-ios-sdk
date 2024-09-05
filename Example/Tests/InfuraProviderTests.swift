//
//  ReadOnlyRPCProviderTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class ReadOnlyRPCProviderTests: XCTestCase {

    var readOnlyRPCProvider: ReadOnlyRPCProvider!
    var mockNetwork: MockNetwork!

    override func setUp() {
        super.setUp()
        mockNetwork = MockNetwork()
        readOnlyRPCProvider = ReadOnlyRPCProvider(infuraAPIKey: "testAPIKey", readonlyRPCMap: [:], network: mockNetwork)
    }

    override func tearDown() {
        readOnlyRPCProvider = nil
        mockNetwork = nil
        super.tearDown()
    }

    func testEndpoint() {
        let ethereumMainnet = readOnlyRPCProvider.endpoint(for: "0x1")
        XCTAssertEqual(ethereumMainnet, "https://mainnet.infura.io/v3/testAPIKey")

        let polygonMainnet = readOnlyRPCProvider.endpoint(for: "0x89")
        XCTAssertEqual(polygonMainnet, "https://polygon-mainnet.infura.io/v3/testAPIKey")

        let unknownChain = readOnlyRPCProvider.endpoint(for: "0x999")
        XCTAssertNil(unknownChain)
    }

    func testSendRequestSuccess() async {
        let mockResponseData = """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "result": "0x1"
        }
        """.data(using: .utf8)!

        mockNetwork.responseData = mockResponseData

        let request = EthereumRequest(id: "1", method: "eth_chainId")
        let appMetadata = AppMetadata(name: "TestApp", url: "https://testapp.com")

        let result = await readOnlyRPCProvider.sendRequest(request, chainId: "0x1", appMetadata: appMetadata)

        XCTAssertEqual(result as? String, "0x1")
    }

    func testSendRequestEndpointUnavailable() async {
        let request = EthereumRequest(id: "1", method: "eth_chainId")
        let appMetadata = AppMetadata(name: "TestApp", url: "https://testapp.com")

        let result = await readOnlyRPCProvider.sendRequest(request, chainId: "0x999", appMetadata: appMetadata)

        XCTAssertNil(result)
    }

    func testSendRequestNetworkError() async {
        mockNetwork.error = NSError(domain: "test", code: 1, userInfo: nil)

        let request = EthereumRequest(id: "1", method: "eth_chainId")
        let appMetadata = AppMetadata(name: "TestApp", url: "https://testapp.com")

        let result = await readOnlyRPCProvider.sendRequest(request, chainId: "0x1", appMetadata: appMetadata)

        XCTAssertNil(result)
    }
}
