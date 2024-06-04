//
//  SessionConfigTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class SessionConfigTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testFutureExpiryDateIsValid() {
        let futureDate = Date(timeIntervalSinceNow: 1000)
        let session = SessionConfig(sessionId: "12345", expiry: futureDate)
        XCTAssertTrue(session.isValid)
    }
    
    func testPastExpiryDateIsInvalid() {
        let pastDate = Date(timeIntervalSinceNow: -10)
        let session = SessionConfig(sessionId: "12345", expiry: pastDate)
        XCTAssertFalse(session.isValid)
    }
}
