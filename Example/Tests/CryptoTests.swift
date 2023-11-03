//
//  CryptoTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
import metamask_ios_sdk

class CryptoTests: XCTestCase {
    //var crypt
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGeneratePrivateKey() {
        let privateKey = Ecies.generatePrivateKey()
        XCTAssertNotNil(privateKey)
    }

    func testPublicKeyFromPrivateKey() {
        let privateKey = Ecies.generatePrivateKey()
        let publicKey = Ecies.publicKey(from: privateKey)
        XCTAssertNotNil(publicKey)
    }
    
    func testEncryptAndDecrypt() {
        // Generate a private key and corresponding public key
        let privateKey = Ecies.generatePrivateKey()
        let publicKey = Ecies.publicKey(from: privateKey)

        // Define a plaintext message to be encrypted
        let plaintext = "Hello, crypto enthusiasts! :)"

        do {
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
}
