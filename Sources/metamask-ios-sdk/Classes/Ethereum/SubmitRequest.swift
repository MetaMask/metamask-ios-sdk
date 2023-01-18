//
//  SubmitRequest.swift
//  metamask-ios-sdk
//

import Combine
import Foundation

struct SubmittedRequest {
    let method: String
    private let requestSubject = PassthroughSubject<Any, RequestError>()

    var publisher: EthereumPublisher? {
        requestSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func send(_ value: Any) {
        requestSubject.send(value)
    }

    func error(_ err: RequestError) {
        requestSubject.send(completion: .failure(err))
    }
}
