//
//  RequestError.swift
//

import Foundation

// MARK: - RequestError

public struct RequestError: Codable, Error {
    public let code: Int
    public let message: String

    init(from info: [String: Any]) {
        code = info["code"] as? Int ?? -1
        message = info["message"] as? String ?? ErrorType(rawValue: code)?.message ?? ""
    }

    public var localizedDescription: String {
        message
    }
}

public extension RequestError {
    var codeType: ErrorType {
        ErrorType(rawValue: code) ?? .unknownError
    }
}
