//
//  MockInfuraProvider.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk
import XCTest

class MockInfuraProvider: InfuraProvider {
    var sendRequestCalled = false
    var response: Any? = "{}"
    var expectation: XCTestExpectation?
    
    override func sendRequest(_ request: any RPCRequest, chainId: String, appMetadata: AppMetadata) async -> Any? {
        sendRequestCalled = true
        expectation?.fulfill()
        return response
    }
}
