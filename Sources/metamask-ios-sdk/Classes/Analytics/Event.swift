//
//  Event.swift
//

public enum Event: String {
    case sdkRpcRequest = "sdk_rpc_request"
    case sdkRpcRequestDone = "sdk_rpc_request_done"
    case connectionRequest = "sdk_connect_request_started"
    case reconnectionRequest = "sdk_reconnect_request_started"
    case connected = "sdk_connection_established"
    case connectionAuthorised = "sdk_connection_authorized"
    case connectionRejected = "sdk_connection_rejected"
    case disconnected = "sdk_disconnected"

    var name: String {
        rawValue
    }
}
