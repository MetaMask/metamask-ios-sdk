//
//  Event.swift
//

public enum Event: String {
    case connectionRequest = "sdk_connect_request_started"
    case connected = "sdk_connection_established"
    case disconnected = "sdk_disconnected"

    var name: String {
        rawValue
    }
}
