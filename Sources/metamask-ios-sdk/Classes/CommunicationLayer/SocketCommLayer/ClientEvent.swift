//
//  ClientEvent.swift
//

import Foundation

public struct ClientEvent {
    public static var connected: String {
        "connection"
    }

    public static var disconnect: String {
        "disconnect"
    }

    public static var message: String {
        "message"
    }
    
    public static var terminate: String {
        "terminate"
    }

    public static var joinChannel: String {
        "join_channel"
    }

    public static func clientsConnected(on channel: String) -> String {
        "clients_connected".appending("-").appending(channel)
    }

    public static func clientDisconnected(on channel: String) -> String {
        "clients_disconnected".appending("-").appending(channel)
    }

    public static func message(on channelId: String) -> String {
        "message".appending("-").appending(channelId)
    }
    
    public static func config(on channelId: String) -> String {
        "config".appending("-").appending(channelId)
    }
}
