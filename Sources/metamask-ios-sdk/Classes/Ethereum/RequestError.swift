//
//  RequestError.swift
//

import Foundation
import Combine

// MARK: - RequestError

public struct RequestError: Codable, Error {
    public let code: Int
    public let message: String

    public init(from info: [String: Any]) {
        code = info["code"] as? Int ?? -1
        if let msg = info["message"] as? String ?? ErrorType(rawValue: code)?.message {
            message = msg
        } else if ErrorType.isServerError(code) {
            message = ErrorType.serverError.message
        } else {
            message = "Something went wrong"
        }
    }

    public var localizedDescription: String {
        message
    }
    
    public static var genericError: RequestError {
        RequestError(from: [
            "code": -100,
            "message": "Something went wrong"
        ])
    }

    public static var connectError: RequestError {
        RequestError(from: [
            "code": -101,
            "message": "Not connected. Please call connect(:Dapp) first"
        ])
    }

    public static var invalidUrlError: RequestError {
        RequestError(from: [
            "code": -102,
            "message": "Please use a valid url in AppMetaData"
        ])
    }

    public static var invalidTitleError: RequestError {
        RequestError(from: [
            "code": -103,
            "message": "Please use a valid name in AppMetaData"
        ])
    }

    public static var invalidBatchRequestError: RequestError {
        RequestError(from: [
            "code": -104,
            "message": "Something went wrong, check that your requests are valid"
        ])
    }
    
    public static var responseError: RequestError {
        RequestError(from: [
            "code": -105,
            "message": "Unexpected response"
        ])
    }

    static func failWithError(_ error: RequestError) -> EthereumPublisher {
        let passthroughSubject = PassthroughSubject<Any, RequestError>()
        let publisher: EthereumPublisher = passthroughSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        passthroughSubject.send(completion: .failure(error))
        return publisher
    }
}

public extension RequestError {
    var codeType: ErrorType {
        guard let errorType = ErrorType(rawValue: code) else {
            return ErrorType.isServerError(code) ? .serverError : .unknownError
        }
        return errorType
    }
}
