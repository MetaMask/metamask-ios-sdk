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
        message = info["message"] as? String ?? ErrorType(rawValue: code)?.message ?? ""
    }

    public var localizedDescription: String {
        message
    }
    
    public static var invalidUrlError: RequestError {
        RequestError(from: [
            "code": -101,
            "message": "Please use a valid dapp url in AppMetaData"
        ])
    }
    
    public static var invalidTitleError: RequestError {
        RequestError(from: [
            "code": -102,
            "message": "Please add a dapp name in AppMetaData"
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
        ErrorType(rawValue: code) ?? .unknownError
    }
}
