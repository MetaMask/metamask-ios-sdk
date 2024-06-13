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
        ethereum = Ethereum.shared(commClient: mockCommClient, trackEvent: trackEventMock)
    }

    override func tearDown() {
        mockCommClient = nil
        trackEventMock = nil
        ethereum = nil
        EthereumWrapper.shared.ethereum = nil
        super.tearDown()
    }
}
