//
//  Network.swift
//

import SwiftUI

protocol Networking: ObservableObject {
    func post(_ parameters: [String: Any], endpoint: Endpoint) async throws
    func fetch<T: Decodable>(_ Type: T.Type, endpoint: Endpoint) async throws -> T
}

class Network: Networking {
    func fetch<T: Decodable>(_ Type: T.Type, endpoint: Endpoint) async throws -> T {
        guard let url = URL(string: endpoint.url) else {
            throw NetworkError.invalidUrl
        }

        let request = request(for: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(Type, from: data)
        return response
    }

    func post(_ parameters: [String: Any], endpoint: Endpoint) async throws {
        guard let url = URL(string: endpoint.url) else {
            throw NetworkError.invalidUrl
        }

        var request = request(for: url)

        let payload = try JSONSerialization.data(withJSONObject: parameters, options: [])
        request.httpBody = payload
        request.httpMethod = "POST"

        _ = try await URLSession.shared.data(for: request)
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
