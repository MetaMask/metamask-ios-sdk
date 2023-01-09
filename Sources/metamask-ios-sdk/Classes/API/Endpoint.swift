//
//  Endpoint.swift
//

import Foundation

enum Endpoint {
    static var SERVER_URL = "https://metamask-sdk-socket.metafi.codefi.network/"

    case analytics

    var url: String {
        switch self {
        case .analytics:
            return Endpoint.SERVER_URL.appending("debug")
        }
    }
}
