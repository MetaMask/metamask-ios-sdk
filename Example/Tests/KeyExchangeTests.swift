//
//  KeyExchangeTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class KeyExchangeTests: XCTestCase {
    
    var keyExchange: KeyExchange!
    
    override func setUp() {
        super.setUp()
        keyExchange = KeyExchange()
    }

    override func tearDown() {
        // Clean up after each test, delete data that might have been saved
        keyExchange = nil
        super.tearDown()
    }
    
    func testDecodingStart() throws {
        let json = "\"key_handshake_start\""
        let data = json.data(using: .utf8)!
        
        do {
            let decodedValue: KeyExchangeType = try JSONDecoder().decode(KeyExchangeType.self, from: data)
            XCTAssertEqual(decodedValue, .start)
        } catch {
            XCTFail("Message could not be decoded: \(error)")
        }
    }
    
    func testDecodingSyn() throws {
        let json = "\"key_handshake_SYN\""
        let data = json.data(using: .utf8)!
        
        do {
            let decodedValue: KeyExchangeType = try JSONDecoder().decode(KeyExchangeType.self, from: data)
            XCTAssertEqual(decodedValue, .syn)
        } catch {
            XCTFail("Message could not be decoded: \(error)")
        }
    }
    
    func testDecodingAck() throws {
        let json = "\"key_handshake_ACK\""
        let data = json.data(using: .utf8)!
        
        do {
            let decodedValue: KeyExchangeType = try JSONDecoder().decode(KeyExchangeType.self, from: data)
            XCTAssertEqual(decodedValue, .ack)
        } catch {
            XCTFail("Message could not be decoded: \(error)")
        }
    }
    
    func testDecodingSynAck() throws {
        let json = "\"key_handshake_SYNACK\""
        let data = json.data(using: .utf8)!
        
        do {
            let decodedValue: KeyExchangeType = try JSONDecoder().decode(KeyExchangeType.self, from: data)
            XCTAssertEqual(decodedValue, .synack)
        } catch {
            XCTFail("Message could not be decoded: \(error)")
        }
    }
    
    func testDecodingUnknown() throws {
        let json = "\"unknown_value\""
        let data = json.data(using: .utf8)!
        
        do {
            let decodedValue: KeyExchangeType = try JSONDecoder().decode(KeyExchangeType.self, from: data)
            XCTAssertEqual(decodedValue, .ack) // default case
        } catch {
            XCTFail("Message could not be decoded: \(error)")
        }
    }
    
    func testInitializeKeyExchangeType() {
        let startKeyExchange = KeyExchangeType(rawValue: "key_handshake_start")
        XCTAssertEqual(startKeyExchange, .start)
        let synKeyExchange = KeyExchangeType(rawValue: "key_handshake_SYN")
        XCTAssertEqual(synKeyExchange, .syn)
        let ackKeyExchange = KeyExchangeType(rawValue: "key_handshake_ACK")
        XCTAssertEqual(ackKeyExchange, .ack)
        let synackKeyExchange = KeyExchangeType(rawValue: "key_handshake_SYNACK")
        XCTAssertEqual(synackKeyExchange, .synack)
    }

    func testKeyExchangeInitialization() {
        // Ensure that pubkey is generated and keysExchanged is initially false
        XCTAssertFalse(keyExchange.keysExchanged)
        XCTAssertNotNil(keyExchange.pubkey)
    }
    
    func testIsHandshakeMessage() {
        //key_handshake_start
        let handShakeMessage = [
            "message": [
                "type": "key_handshake_start"
            ]
        ]
        
        let notHandShakeMessage = [
            "message": [
                "type": "key_handshake_SYN"
            ]
        ]
        
        XCTAssertTrue(KeyExchange.isHandshakeRestartMessage(handShakeMessage))
        XCTAssertFalse(KeyExchange.isHandshakeRestartMessage(notHandShakeMessage))
    }
    
    func testMessageFromKeyExchangeType() {
        let message = keyExchange.message(type: .syn)
        XCTAssertEqual(message.type, .syn)
        XCTAssertEqual(message.pubkey, keyExchange.pubkey)
    }
    
    func testKeyExchangeMessageSocketRepresentation() {
        let pubkey = "0xhexabcdefgh"
        let type: KeyExchangeType = .synack
        let message = KeyExchangeMessage(type: type, pubkey: pubkey)
        let socketRep = message.socketRepresentation() as? [String: String] ?? [:]
        XCTAssertEqual(message.type, type)
        XCTAssertEqual(message.pubkey, pubkey)
        XCTAssertEqual(socketRep["type"], "key_handshake_SYNACK")
        XCTAssertEqual(socketRep["pubkey"], pubkey)
    }
    
    func testNextStep() {
        let handShakeStep: KeyExchangeType = .start
        let synStep = keyExchange.nextStep(handShakeStep) ?? handShakeStep
        XCTAssertEqual(synStep, .syn)
        let synAckStep = keyExchange.nextStep(synStep) ?? handShakeStep
        XCTAssertEqual(synAckStep, .synack)
        let ackStep = keyExchange.nextStep(synAckStep) ?? handShakeStep
        XCTAssertEqual(ackStep, .ack)
        let endStep = keyExchange.nextStep(ackStep)
        XCTAssertNil(endStep)
    }

    func testKeyExchangeNextMessage() {
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
    
    func testKeyExchangeSetsTheirPubKeyWhenMessageHasPubKey() {
        let pubkey = "0xabcdefgh"
        let messageWithPublickKey = KeyExchangeMessage(type: .start, pubkey: pubkey)
        XCTAssertEqual(keyExchange.theirPublicKey, nil)
        let nextMessage = keyExchange.nextMessage(messageWithPublickKey)
        XCTAssertEqual(keyExchange.theirPublicKey, pubkey)
    }
    
    func testKeyExchangeSetsKeysExchangedFlagWhenMessageHasPubKey() {
        let pubkey = "0xabcdefgh"
        let messageWithPublickKey = KeyExchangeMessage(type: .start, pubkey: pubkey)
        XCTAssertFalse(keyExchange.keysExchanged)
        let nextMessage = keyExchange.nextMessage(messageWithPublickKey)
        XCTAssertTrue(keyExchange.keysExchanged)
    }
    
    func testStringEncryptAndDecryption() {
        let keyExchangeAlice = KeyExchange()
        let keyExchangeBob = KeyExchange()

        // Exchange public keys between two parties
        keyExchangeAlice.setTheirPublicKey(keyExchangeBob.pubkey)
        keyExchangeBob.setTheirPublicKey(keyExchangeAlice.pubkey)

        // Test encryption and decryption of a message
        let originalMessage = "Message to encrypt"
        
        do {
            let aliceEncryptedMessage = try keyExchangeAlice.encrypt(originalMessage)
            
            do {
                let bobDecryptedMessage = try keyExchangeBob.decryptMessage(aliceEncryptedMessage)
                XCTAssertEqual(bobDecryptedMessage, originalMessage)
            } catch {
                XCTFail("Message could not be decoded: \(error)")
            }
        } catch {
            XCTFail("Message could not be encrpyted: \(error)")
        }
    }

    func testMessageEncryptionAndDecryption() {
        let keyExchangeAlice = KeyExchange()
        let keyExchangeBob = KeyExchange()

        // Exchange public keys between two parties
        keyExchangeAlice.setTheirPublicKey(keyExchangeBob.pubkey)
        keyExchangeBob.setTheirPublicKey(keyExchangeAlice.pubkey)

        // Test encryption and decryption of a message
        let originalMessage = SocketMessage(id: "1234", message: "Mayday, mayday Planet 1804!")
        do {
            let aliceEncryptedMessage = try keyExchangeAlice.encryptMessage(originalMessage.toJsonString() ?? "")
            let bobDecryptedMessage = try keyExchangeBob.decryptMessage(aliceEncryptedMessage)
            let json: [String: Any] = try JSONSerialization.jsonObject(
                with: Data(bobDecryptedMessage.utf8),
                options: []
            )
                as? [String: Any] ?? [:]
            do {
                let message = try SocketMessage<String>.message(from: json)
                let bobEncryptedMessage = try keyExchangeBob.encryptMessage(message.message)
                let aliceDecryptedMessage = try keyExchangeAlice.decryptMessage(bobEncryptedMessage)
                XCTAssertEqual(message.id, originalMessage.id)
                XCTAssertEqual(message.message, originalMessage.message)
                XCTAssertEqual(aliceDecryptedMessage, originalMessage.message)
            } catch {
                XCTFail("Message could not be decoded: \(error)")
            }

        } catch {
            XCTFail("Encryption or decryption failed with error: \(error)")
        }
    }
    
    func testEncryptWithoutTheirPublicKeyThrows() {
        let keyExchangeAlice = KeyExchange()
        let keyExchangeBob = KeyExchange()

        // Exchange public keys between two parties
        keyExchangeBob.setTheirPublicKey(keyExchangeAlice.pubkey)

        // Test encryption and decryption of a message
        let originalMessage = "Message to encrypt"
        
        do {
            let aliceEncryptedMessage = try keyExchangeAlice.encrypt(originalMessage)
            
        } catch {
            XCTAssertEqual(error as? KeyExchangeError, KeyExchangeError.keysNotExchanged)
        }
    }
    
    func testDecryptWithoutTheirPublicKeyThrows() {
        let keyExchangeAlice = KeyExchange()
        let keyExchangeBob = KeyExchange()

        // Exchange public keys between two parties
        keyExchangeAlice.setTheirPublicKey(keyExchangeBob.pubkey)

        // Test encryption and decryption of a message
        let originalMessage = "Message to encrypt"
        
        do {
            let aliceEncryptedMessage = try keyExchangeAlice.encrypt(originalMessage)
            
            do {
                let bobDecryptedMessage = try keyExchangeBob.decryptMessage(aliceEncryptedMessage)
            } catch {
                XCTAssertEqual(error as? KeyExchangeError, KeyExchangeError.keysNotExchanged)
            }
            
        } catch {
            XCTFail("Message could not be encrypted: \(error)")
        }
    }
    
    func testEncryptWithInvalidData() {
        let keyExchangeAlice = KeyExchange()
        let keyExchangeBob = KeyExchange()

        // Exchange public keys between two parties
        keyExchangeAlice.setTheirPublicKey(keyExchangeBob.pubkey)
        
        let originalMessage = Data()
        
        do {
            let _ = try keyExchangeAlice.encryptMessage(originalMessage)
        } catch {
            XCTAssertEqual(error as? KeyExchangeError, KeyExchangeError.encodingError)
        }
    }

    func testKeyExchangeReset() {
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
