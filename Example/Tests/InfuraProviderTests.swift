//
//  InfuraProviderTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class InfuraProviderTests: XCTestCase {

    var infuraProvider: InfuraProvider!
    var mockNetwork: MockNetwork!

    override func setUp() {
        super.setUp()
        mockNetwork = MockNetwork()
        infuraProvider = InfuraProvider(infuraAPIKey: "testAPIKey", network: mockNetwork)
    }

    override func tearDown() {
        infuraProvider = nil
        mockNetwork = nil
        super.tearDown()
    }

    func testEndpoint() {
        let ethereumMainnet = infuraProvider.endpoint(for: "0x1")
        XCTAssertEqual(ethereumMainnet, "https://mainnet.infura.io/v3/testAPIKey")

        let polygonMainnet = infuraProvider.endpoint(for: "0x89")
        XCTAssertEqual(polygonMainnet, "https://polygon-mainnet.infura.io/v3/testAPIKey")

        let unknownChain = infuraProvider.endpoint(for: "0x999")
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

        let result = await infuraProvider.sendRequest(request, chainId: "0x1", appMetadata: appMetadata)

        XCTAssertEqual(result as? String, "0x1")
    }

    func testSendRequestEndpointUnavailable() async {
        let request = EthereumRequest(id: "1", method: "eth_chainId")
        let appMetadata = AppMetadata(name: "TestApp", url: "https://testapp.com")

        let result = await infuraProvider.sendRequest(request, chainId: "0x999", appMetadata: appMetadata)

        XCTAssertNil(result)
    }

    func testSendRequestNetworkError() async {
        mockNetwork.error = NSError(domain: "test", code: 1, userInfo: nil)

        let request = EthereumRequest(id: "1", method: "eth_chainId")
        let appMetadata = AppMetadata(name: "TestApp", url: "https://testapp.com")

        let result = await infuraProvider.sendRequest(request, chainId: "0x1", appMetadata: appMetadata)

        XCTAssertNil(result)
    }

    // Mock classes for testing
    class MockNetwork: Networking {
        func post(_ parameters: [String : Any], endpoint: String) async throws -> Data {
            if let error = error {
                throw error
            }

            return responseData ?? Data()
        }
        
        var responseData: Data?
        var error: Error?
        
        func post(_ parameters: [String : Any], endpoint: Endpoint) async throws -> Data {
            if let error = error {
                throw error
            }

            return responseData ?? Data()
        }
        
        func fetch<T>(_ Type: T.Type, endpoint: Endpoint) async throws -> T where T : Decodable {
            return responseData as! T
        }

            
        func addHeaders(_ headers: [String : String]) {
            // Mock implementation
        }
    }
}
