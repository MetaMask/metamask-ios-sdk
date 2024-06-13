//
//  EthereumRequestTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class EthereumRequestTests: XCTestCase {
    
    func testInitializationWithStringMethod() {
        let params = ["from": "0x1234567890", "to": "0x0987654321"]
        let request = EthereumRequest(id: "12345", method: "eth_sendTransaction", params: params)
        
        XCTAssertEqual(request.id, "12345")
        XCTAssertEqual(request.method, "eth_sendTransaction")
        XCTAssertEqual(request.params, params)
        XCTAssertEqual(request.methodType, .ethSendTransaction)
    }
    
    func testInitializationWithEthereumMethod() {
        let params = ["0x1234567890", "latest"]
        let request = EthereumRequest(id: "12345", method: .ethGetBalance, params: params)
        
        XCTAssertEqual(request.id, "12345")
        XCTAssertEqual(request.method, "eth_getBalance")
        XCTAssertEqual(request.params, params)
        XCTAssertEqual(request.methodType, .ethGetBalance)
    }
    
    func testEthereumMethodHasIdByDefault() {
        let params = ["0x1234567890", "latest"]
        let request = EthereumRequest(method: .ethGetBalance, params: params)
        
        XCTAssertNotNil(request.id)
        XCTAssertNotEqual(request.id, "")
    }
    
    func testKnownMethodTypeConversion() {
        let params = ["from": "0x1234567890", "to": "0x0987654321"]
        let request = EthereumRequest(id: "12345", method: "eth_sendTransaction", params: params)

        XCTAssertEqual(request.methodType, .ethSendTransaction)
    }
    
    func testUnknownMethodTypeConversion() {
        let params = ["from": "0x1234567890", "to": "0x0987654321"]
        let unknownRequest = EthereumRequest(id: "12345", method: "eth_unknown_method", params: params)

        XCTAssertEqual(unknownRequest.methodType, .unknownMethod)
    }
    
    func testDictionarySocketRepresentation() {
        let params = ["from": "0x1234567890", "to": "0x0987654321"]
        let request = EthereumRequest(id: "12345", method: .ethSendTransaction, params: params)
        let socketRep = request.socketRepresentation() as? [String: Any] ?? [:]
        
        XCTAssertEqual(socketRep["id"] as? String, "12345")
        XCTAssertEqual(socketRep["method"] as? String, "eth_sendTransaction")
        XCTAssertEqual(socketRep["parameters"] as? [String: String], params)
    }
    
    func testArraySocketRepresentation() {
        let params = ["0x1234567890", "latest"]
        let request = EthereumRequest(id: "24680", method: .ethGetBalance, params: params)
        let socketRep = request.socketRepresentation() as? [String: Any] ?? [:]
        
        XCTAssertEqual(socketRep["id"] as? String, "24680")
        XCTAssertEqual(socketRep["method"] as? String, "eth_getBalance")
        XCTAssertEqual(socketRep["parameters"] as? [String], params)
    }
    
    func testEmptyParamsInitialization() {
        let request = EthereumRequest(id: "12345", method: "eth_sendTransaction")

        XCTAssertEqual(request.id, "12345")
        XCTAssertEqual(request.method, "eth_sendTransaction")
        XCTAssertEqual(request.params, "")
        XCTAssertEqual(request.methodType, .ethSendTransaction)
    }
    
    func testEmptyParamsInitializationWithMethodEnum() {
        let request = EthereumRequest(id: "12345", method: .ethGetBalance)

        XCTAssertEqual(request.id, "12345")
        XCTAssertEqual(request.method, "eth_getBalance")
        XCTAssertEqual(request.params, "")
        XCTAssertEqual(request.methodType, .ethGetBalance)
    }
    
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

struct Transaction: CodableData {
    let to: String
    let from: String
    let value: String
    let data: String?

    init(to: String, from: String, value: String, data: String? = nil) {
        self.to = to
        self.from = from
        self.value = value
        self.data = data
    }

    func socketRepresentation() -> NetworkData {
        [
            "to": to,
            "from": from,
            "value": value,
            "data": data ?? ""
        ]
    }
}

struct TimestampGenerator {
    static func timestamp() -> String {
        return "\(Date().timeIntervalSince1970)"
    }
}

enum EthereumMethod: String {
    case ethSendTransaction = "eth_sendTransaction"
    case ethGetBalance = "eth_getBalance"
    case unknownMethod
}
