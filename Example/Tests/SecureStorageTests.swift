//
//  SecureStorageTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class KeychainTests: XCTestCase {
    var keychain: SecureStore!
    var testKey = "testKey"

    override func setUp() {
        super.setUp()
        keychain = Keychain(service: "com.example.testKeychain")
    }

    override func tearDown() {
        // Clean up after each test, delete data that might have been saved
        keychain.deleteData(for: testKey)
        super.tearDown()
    }

    func testSaveAndRetrieveString() {
        let value = "String input"

        // Save a string
        XCTAssertTrue(keychain.save(string: value, key: testKey))

        // Retrieve the saved string
        let retrievedValue = keychain.string(for: testKey)

        XCTAssertEqual(retrievedValue, value)
    }

    func testSaveAndOverwriteString() {
        let initialValue = "Initial string input"
        keychain.save(string: initialValue, key: testKey)

        let replacementValue = "Replacement string input"
        keychain.save(string: replacementValue, key: testKey)

        // Retrieve the last saved string for key
        let retrievedValue = keychain.string(for: testKey)

        XCTAssertEqual(retrievedValue, replacementValue)
    }

    func testSaveAndRetrieveData() {
        guard let data = "Test Data".data(using: .utf8) else {
            XCTFail("Could not convert string to data")
            return
        }

        // Save data
        XCTAssertTrue(keychain.save(data: data, key: testKey))

        // Retrieve the saved data
        let retrievedData = keychain.data(for: testKey)

        XCTAssertEqual(retrievedData, data)
    }

    func testDeleteString() {
        let value = "Test String"

        // Save a string
        XCTAssertTrue(keychain.save(string: value, key: testKey))

        // Delete the saved data
        XCTAssertTrue(keychain.deleteData(for: testKey))

        // Attempt to retrieve the deleted data
        let retrievedValue = keychain.string(for: testKey)

        XCTAssertNil(retrievedValue)
    }

    func testDeleteData() {
        guard let data = "Test String".data(using: .utf8) else {
            XCTFail("Could not convert string to data")
            return
        }

        // Save a string
        XCTAssertTrue(keychain.save(data: data, key: testKey))

        // Delete the saved data
        XCTAssertTrue(keychain.deleteData(for: testKey))

        // Attempt to retrieve the deleted data
        let retrievedValue = keychain.data(for: testKey)

        XCTAssertNil(retrievedValue)
    }

    func testSaveAndRetrievModel() {
        let sessionId = "SHDKy-SSY872-FGHQ"
        let date = Date()

        let sessionConfigModel = SessionConfig(
            sessionId: sessionId,
            expiry: date)

        guard let sessionConfigModelData = try? JSONEncoder().encode(sessionConfigModel) else {
            XCTFail("Could not convert SessionConfig to data")
            return
        }

        // Encode and save a Codable object
        XCTAssertTrue(keychain.save(data: sessionConfigModelData, key: testKey))

        // Retrieve and decode the saved model
        guard let retrievedModel: SessionConfig = keychain.model(for: testKey) else {
            XCTFail("Could not create SessionConfig model from data")
            return
        }

        XCTAssertEqual(retrievedModel, sessionConfigModel)
    }
}
