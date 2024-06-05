//
//  KeyExchangeTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class KeyExchangeTests: XCTestCase {

    func testKeyExchangeInitialization() {
        let keyExchange = KeyExchange()

        // Ensure that pubkey is generated and keysExchanged is initially false
        XCTAssertFalse(keyExchange.keysExchanged)
        XCTAssertNotNil(keyExchange.pubkey)
    }

    func testKeyExchangeNextMessage() {
        let keyExchange = KeyExchange()
        let startMessage = KeyExchangeMessage(type: .start, pubkey: nil)

        // Test the nextMessage function with a start message
        let synMessage = keyExchange.nextMessage(startMessage)
        XCTAssertEqual(synMessage?.type, .syn)
        XCTAssertEqual(synMessage?.pubkey, keyExchange.pubkey)

        // Test the nextMessage function with a syn message
        let synackMessage = keyExchange.nextMessage(KeyExchangeMessage(type: .syn, pubkey: nil))
        XCTAssertEqual(synackMessage?.type, .synack)
        XCTAssertEqual(synackMessage?.pubkey, keyExchange.pubkey)

        // Test the nextMessage function with an ack message
        let ackMessage = keyExchange.nextMessage(KeyExchangeMessage(type: .synack, pubkey: nil))
        XCTAssertEqual(ackMessage?.type, .ack)
        XCTAssertEqual(ackMessage?.pubkey, keyExchange.pubkey)

        // Test the nextMessage function with an unexpected message
        let unexpectedMessage = keyExchange.nextMessage(KeyExchangeMessage(type: .ack, pubkey: nil))
        XCTAssertNil(unexpectedMessage)
    }

    func testKeyExchangeEncryptionAndDecryption() {
        let keyExchangeAlice = KeyExchange()
        let keyExchangeBob = KeyExchange()

        // Exchange public keys between two parties
        keyExchangeAlice.setTheirPublicKey(keyExchangeBob.pubkey)
        keyExchangeBob.setTheirPublicKey(keyExchangeAlice.pubkey)

        // Test encryption and decryption of a message
        let originalMessage = SocketMessage(id: "1234", message: "Mayday, mayday Planet 1804!")
        do {
            let encryptedMessage = try keyExchangeAlice.encryptMessage(originalMessage.toJsonString() ?? "")
            let decryptedMessage = try keyExchangeBob.decryptMessage(encryptedMessage)
            let json: [String: Any] = try JSONSerialization.jsonObject(
                with: Data(decryptedMessage.utf8),
                options: []
            )
                as? [String: Any] ?? [:]
            do {
                let message = try SocketMessage<String>.message(from: json)
                XCTAssertEqual(message.id, originalMessage.id)
                XCTAssertEqual(message.message, originalMessage.message)
            } catch {
                XCTFail("Message could not be decoded: \(error)")
            }

        } catch {
            XCTFail("Encryption or decryption failed with error: \(error)")
        }
    }

    func testKeyExchangeReset() {
        let keyExchange = KeyExchange()
        let publicKey = keyExchange.pubkey
        keyExchange.setTheirPublicKey("testPublicKey")

        // Reset the key exchange
        keyExchange.reset()

        // Verify that values are reset
        XCTAssertFalse(keyExchange.keysExchanged)
        XCTAssertNil(keyExchange.theirPublicKey)
        XCTAssertNotEqual(keyExchange.pubkey, publicKey)
    }

    func testKeyExchangeErrorHandling() {
        let keyExchange = KeyExchange()

        // Attempt to encrypt a message without exchanging keys
        XCTAssertThrowsError(try keyExchange.encryptMessage("Test Message")) { error in
            XCTAssertTrue(error is KeyExchangeError)
            XCTAssertEqual(error as? KeyExchangeError, .keysNotExchanged)
        }

        // Attempt to decrypt a message without exchanging keys
        XCTAssertThrowsError(try keyExchange.decryptMessage("Encrypted Message")) { error in
            XCTAssertTrue(error is KeyExchangeError)
            XCTAssertEqual(error as? KeyExchangeError, .keysNotExchanged)
        }
    }
}
