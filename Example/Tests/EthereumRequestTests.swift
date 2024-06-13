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
        let unknownRequest = EthereumRequest(id: "12345", method: "eth_unkown_method", params: params)

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
    
    func testStructSocketRepresentation() {
        let transaction = Transaction(
            to: "0x0000000000000000000000000000000000000000",
            from: "0x1234567890",
            value: "0x000000000000000001"
        )

        let parameters: [Transaction] = [transaction]

        let transactionRequest = EthereumRequest(
            id: "24680",
            method: .ethSendTransaction,
            params: parameters
        )
        
        let socketRep = transactionRequest.socketRepresentation() as? [String: Any] ?? [:]
        
        XCTAssertEqual(socketRep["id"] as? String, "24680")
        XCTAssertEqual(socketRep["method"] as? String, "eth_sendTransaction")
        
        let socketParams = socketRep["parameters"] as? [Transaction] ?? []
        XCTAssertEqual(socketParams.first?.from, "0x1234567890")
        XCTAssertEqual(socketParams.first?.to, "0x0000000000000000000000000000000000000000")
        XCTAssertEqual(socketParams.first?.value, "0x000000000000000001")
        XCTAssertNil(socketParams.first?.data)
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
            "data": data
        ]
    }
}
