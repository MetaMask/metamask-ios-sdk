//
//  Event.swift
//

public enum Event: String {
    case connectionRequest = "sdk_connect_request_started"
    case connected = "sdk_connection_established"
    case connectionAuthorised = "sdk_connection_authorized"
    case connectionRejected = "sdk_connection_rejected"
    case disconnected = "sdk_disconnected"

    var name: String {
        rawValue
    }
}
