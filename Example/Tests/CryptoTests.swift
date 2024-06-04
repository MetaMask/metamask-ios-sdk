//
//  CryptoTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class CryptoTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testGeneratePrivateKey() {
        let privateKey = Ecies.generatePrivateKey()
        XCTAssertNotNil(privateKey)
    }

    func testPublicKeyFromPrivateKey() {
        let privateKey = Ecies.generatePrivateKey()
        let publicKey = try? Ecies.publicKey(from: privateKey)
        XCTAssertNotNil(publicKey)
    }
    
    func testEncryptAndDecrypt() {
        // Generate a private key and corresponding public key
        let privateKey = Ecies.generatePrivateKey()
        
        // Define a plaintext message to be encrypted
        let plaintext = "Hello, crypto enthusiasts! :)"

        do {
            let publicKey = try Ecies.publicKey(from: privateKey)
            // Encrypt the plaintext
            let encryptedText = try Ecies.encrypt(plaintext, publicKey: publicKey)

            // Decrypt the encrypted text
            do {
                let decryptedText = try Ecies.decrypt(encryptedText, privateKey: privateKey)

                // Check if the decrypted text is the same as the original plaintext
                XCTAssertEqual(decryptedText, plaintext)
            } catch {
                XCTFail("CryptoTests:: Decryption failed with error: \(error)")
            }
        } catch {
            XCTFail("CryptoTests:: Encryption failed with error: \(error)")
        }
    }
    
    func testGeneratePublicKeyWithInvalidPrivateKeyShouldFail() {
        // Generate a private key and corresponding public key
        let privateKey = Ecies.generatePrivateKey()
        let modifiedPrivateKey = privateKey.dropLast().appending("")

        do {
            let _ = try Ecies.publicKey(from: modifiedPrivateKey)
            XCTFail("CryptoTests:: Public key generation should fail")
        } catch {
            XCTAssert(error as? CryptoError == CryptoError.publicKeyGenerationFailure)
        }
    }
    
    
    func testEncryptWithInvalidPublicKeyShouldFail() {
        let privateKey = Ecies.generatePrivateKey()
        let plaintext = "Hello, crypto enthusiasts! :)"

        do {
            let publicKey = try Ecies.publicKey(from: privateKey)
            
            let modifiedPublicKey = publicKey.dropLast().appending("")
            let _ = try Ecies.encrypt(plaintext, publicKey: modifiedPublicKey)
            XCTFail("CryptoTests:: Encryption with invalid public key should fail")
        } catch {
            XCTAssert(error as? CryptoError == CryptoError.encryptionFailure)
        }
    }
    
    func testDecryptWithInvalidPrivateKeyShouldFail() {
        let privateKey = Ecies.generatePrivateKey()
        let plaintext = "Hello, crypto enthusiasts! :)"

        do {
            let publicKey = try Ecies.publicKey(from: privateKey)
            
            let encryptedText = try Ecies.encrypt(plaintext, publicKey: publicKey)
            let modifiedPrivateKey = privateKey.dropLast().appending("")
            let _ = try Ecies.decrypt(encryptedText, privateKey: modifiedPrivateKey)
            XCTFail("CryptoTests:: Decryption with invalid private key should fail")
        } catch {
            XCTAssert(error as? CryptoError == CryptoError.decryptionFailure)
        }
    }
}
