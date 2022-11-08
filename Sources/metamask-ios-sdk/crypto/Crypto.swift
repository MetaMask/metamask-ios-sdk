import Foundation

/// Encryption module using the public key authentication standard
public protocol Encryption {
    /// Generates a private key
    var privateKey: String { get }
    
    /// Computes public key from given private key
    var publicKey: String { get }
    
    /// Encrypts the supplied plain text using provided public key
    /// - Parameters:
    ///   - message: Plain text to encrypt
    ///   - publicKey: Sender public key to encrypt with
    /// - Returns: Encrypted text
    func encrypt(_ message: String, publicKey: String) -> String
    
    
    /// Decrypts the supplied cyphertext with the provided private key
    /// - Parameters:
    ///   - message: Cyphertext to decrypt
    ///   - privateKey: Private key to decrypt with
    /// - Returns: Decrypted plain text
    func decrypt(_ message: String, privateKey: String) -> String
}

/// Encryption implementation using ECIES encryption standard
public struct ECIES: Encryption {
    private let _privateKey: String
    
    public init() {
        _privateKey = "" // generate ECIES private key
    }
    
    public var privateKey: String {
        _privateKey
    }
    
    public var publicKey: String {
        "" // generate public key from private key
    }
    
    public func encrypt(_ message: String, publicKey: String) -> String {
        ""
    }
    
    public func decrypt(_ message: String, privateKey: String) -> String {
        ""
    }
}

