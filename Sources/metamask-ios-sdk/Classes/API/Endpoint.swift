//
//  Endpoint.swift
//

import Foundation

public enum Endpoint {
    public static var SERVER_URL = "http://localhost:4000/" //"https://metamask-sdk.api.cx.metamask.io/"

    case analytics

    public var url: String {
        switch self {
        case .analytics:
            return Endpoint.SERVER_URL.appending("debug")
        }
    }
}
