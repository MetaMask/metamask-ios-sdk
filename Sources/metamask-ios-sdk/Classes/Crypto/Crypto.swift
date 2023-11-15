import Ecies
import Foundation

public protocol Crypto {
    /// Generates keypair and returns the asymmetric private key
    /// - Returns: Asymmetric private key
    static func generatePrivateKey() -> String

    /// Computes public key from given private key
    /// - Parameter privateKey: Sender's private key
    /// - Returns: Public key
    static func publicKey(from privateKey: String) throws -> String

    /// Encrypts plain text using provided public key
    /// - Parameters:
    ///   - message: Plain text to encrypt
    ///   - publicKey: Sender public key
    /// - Returns: Encrypted text
    static func encrypt(_ message: String, publicKey: String) throws -> String

    /// Decrypts base64 encoded cipher text to plain text using provided private key
    /// - Parameters:
    ///   - message: base64 encoded cipher text to decrypt
    ///   - privateKey: Receiever's private key
    /// - Returns: Decryted plain text
    static func decrypt(_ message: String, privateKey: String) throws -> String
}

public enum CryptoError: Error {
    case encryptionFailure
    case decryptionFailure
    case publicKeyGenerationFailure
}

/// Encryption module using ECIES encryption standard
public enum Ecies: Crypto {
    public static func generatePrivateKey() -> String {
        String(cString: ecies_generate_secret_key())
    }

    public static func publicKey(from privateKey: String) throws -> String {
        let privateKey: NSString = privateKey as NSString
        let privateKeyBytes = UnsafeMutablePointer(mutating: privateKey.utf8String)
        guard let pubKeyCString = ecies_public_key_from(privateKeyBytes) else {
            throw CryptoError.publicKeyGenerationFailure
        }
        return String(cString: pubKeyCString)
    }

    public static func encrypt(_ message: String, publicKey: String) throws -> String {
        let message: NSString = message as NSString
        let publicKey: NSString = publicKey as NSString
        let messageBytes = UnsafeMutablePointer(mutating: message.utf8String)
        let publicKeyBytes = UnsafeMutablePointer(mutating: publicKey.utf8String)

        guard let encryptedText = ecies_encrypt(publicKeyBytes, messageBytes) else {
            throw CryptoError.encryptionFailure
        }
        return String(cString: encryptedText)
    }

    public static func decrypt(_ message: String, privateKey: String) throws -> String {
        let message: NSString = message as NSString
        let privateKey: NSString = privateKey as NSString
        let messageBytes = UnsafeMutablePointer(mutating: message.utf8String)
        let privateKeyBytes = UnsafeMutablePointer(mutating: privateKey.utf8String)
        guard let decryptedText = ecies_decrypt(privateKeyBytes, messageBytes) else {
            throw CryptoError.decryptionFailure
        }
        return String(cString: decryptedText)
    }
}
