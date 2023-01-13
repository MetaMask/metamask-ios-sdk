//
//  RequestError.swift
//

import Foundation

// MARK: - RequestError
public struct RequestError: Codable, Error {
    public let code: Int
    public let data: DataInfo?
    public let message: String
    
    init(code: Int, message: String) {
        self.code = code
        self.data = nil
        self.message = message
    }
    
    init(from dictionary: [String: Any]) {
        let defaultError = RequestError(code: -1, message: "The request failed")
        guard
            let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
            let value = try? JSONDecoder().decode(Self.self, from: data) else {
            print("Could not handle error: \(dictionary)")
            self = defaultError
            return
        }
        self = value
    }
    
    public var localizedDescription: String {
        message
    }
}

public extension RequestError {
    var codeType: ErrorType {
        ErrorType(rawValue: code) ?? .unknown
    }
}

// MARK: - DataInfo
public struct DataInfo: Codable {
    let originalError: OriginalError
}

// MARK: - OriginalError
public struct OriginalError: Codable {
}
