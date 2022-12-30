//
//  Endpoint.swift
//

import Foundation

enum Endpoint {
    static let SOCKET_IO_SERVER =  "https://metamask-sdk-socket.metafi.codefi.network/"
    
    case analytics
    
    var url: String {

        switch self {
        case .analytics:
            return Endpoint.SOCKET_IO_SERVER.appending("debug")
        }
    }
}
