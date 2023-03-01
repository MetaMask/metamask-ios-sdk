//
//  Endpoint.swift
//

import Foundation

enum Endpoint {
    static var SERVER_URL = "http://192.168.50.114:4000"//"https://metamask-sdk-socket.metafi.codefi.network/"

    case analytics

    var url: String {
        switch self {
        case .analytics:
            return Endpoint.SERVER_URL.appending("debug")
        }
    }
}
