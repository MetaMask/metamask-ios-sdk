//
//  Endpoint.swift
//

import Foundation

public enum Endpoint {
    public static var SERVER_URL = "https://metamask-sdk-socket.metafi.codefi.network/"

    case analytics

    public var url: String {
        switch self {
        case .analytics:
            return Endpoint.SERVER_URL.appending("debug")
        }
    }
}
