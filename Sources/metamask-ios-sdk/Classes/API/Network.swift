//
//  Network.swift
//

import SwiftUI

public protocol Networking: ObservableObject {
    func addHeaders(_ headers: [String: String])
    @discardableResult
    func post(_ parameters: [String: Any], endpoint: Endpoint) async throws -> Data
    func post(_ parameters: [String: Any], endpoint: String) async throws -> Data
    func fetch<T: Decodable>(_ Type: T.Type, endpoint: Endpoint) async throws -> T
}

public class Network: Networking {
    public init() {}
    
    private let queue = DispatchQueue(label: "headers.queue")

    private var additionalHeaders: [String: String] = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]
    
    func getAdditionalHeaders() -> [String: String] {
        return queue.sync { [weak self] in
            return self?.additionalHeaders ?? [:]
        }
    }
    
    func mergeHeaders(_ headers: [String: String]) {
        queue.sync {
            additionalHeaders.merge(headers) { (_, new) in new }
        }
    }

    public func fetch<T: Decodable>(_ Type: T.Type, endpoint: Endpoint) async throws -> T {
        guard let url = URL(string: endpoint.url) else {
            throw NetworkError.invalidUrl
        }

        let request = request(for: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(Type, from: data)
        return response
    }

    @discardableResult
    public func post(_ parameters: [String: Any], endpoint: Endpoint) async throws -> Data {
        try await post(parameters, endpoint: endpoint.url)
    }

    public func post(_ parameters: [String: Any], endpoint: String) async throws -> Data {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidUrl
        }

        var request = request(for: url)

        let payload = try JSONSerialization.data(withJSONObject: parameters, options: [])
        request.httpBody = payload
        request.httpMethod = "POST"

        let response = try await URLSession.shared.data(for: request)
        return response.0
    }

    public func addHeaders(_ headers: [String: String]) {
        mergeHeaders(headers)
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        for (key, value) in getAdditionalHeaders() {
            request.addValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}
