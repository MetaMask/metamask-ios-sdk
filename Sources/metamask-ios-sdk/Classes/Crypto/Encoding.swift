import Foundation

public extension String {
    // Encode a string to base64
    func base64Encode() -> String? {
        guard let data = data(using: .utf8) else { return nil }
        return data.base64EncodedString()
    }

    // Decode a base64 string to original string
    func base64Decode() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
