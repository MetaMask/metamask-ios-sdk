//
//  RequestError.swift
//

import Foundation

// MARK: - RequestError

public struct RequestError: Codable, Error {
    public let code: Int
    public let message: String

    public init(from info: [String: Any]) {
        code = info["code"] as? Int ?? -1
        message = info["message"] as? String ?? ErrorType(rawValue: code)?.message ?? ""
    }

    public var localizedDescription: String {
        message
    }
    
    public static var connectError: RequestError {
        RequestError(from: [
            "code": -1,
            "message": "Not connected. Please call connect(:Dapp) first"
        ])
    }
}

public extension RequestError {
    var codeType: ErrorType {
        ErrorType(rawValue: code) ?? .unknownError
    }
}
