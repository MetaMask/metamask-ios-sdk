import Foundation

/// Encryption module using ECIES encryption standard
public protocol Encryption {
    /// Generates keypair and returns the asymmetric private key
    /// - Returns: Asymmetric private key
    static func generatePrivateKey() -> String
    
    /// Computes public key from given private key
    /// - Parameter privateKey: Sender's private key
    /// - Returns: Public key
    static func publicKey(from privateKey: String) -> String
    
    /// Encrypts plain text using provided public key
    /// - Parameters:
    ///   - message: Plain text to encrypt
    ///   - publicKey: Sender public key
    /// - Returns: Encrypted text
    static func encrypt(_ message: String, publicKey: String) -> String
}

struct ECIES: Encryption {
    static func generatePrivateKey() -> String {
        ""
    }
    
    static func publicKey(from privateKey: String) -> String {
        ""
    }
    
    static func encrypt(_ message: String, publicKey: String) -> String {
        ""
    }
}

