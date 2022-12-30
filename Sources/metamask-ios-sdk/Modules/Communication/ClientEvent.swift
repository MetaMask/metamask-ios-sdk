//
//  ClientEvent.swift
//

import Foundation

struct ClientEvent {
    static var connected: String {
        "connection"
    }

    static var disconnect: String {
        "disconnect"
    }

    static var message: String {
        "message"
    }

    static var keyExchange: String {
        "key_exchange"
    }

    static var keysExchanged: String {
        "keys_exchanged"
    }

    static var joinChannel: String {
        "join_channel"
    }

    static var createChannel: String {
        "create_channel"
    }

    static func waitingToJoin(_ channel: String) -> String {
        "clients_waiting_to_join".appending("-").appending(channel)
    }

    static func channelCreated(_ channel: String) -> String {
        "channel_created".appending("-").appending(channel)
    }

    static func clientsConnected(on channel: String) -> String {
        "clients_connected".appending("-").appending(channel)
    }

    static func clientDisconnected(on channel: String) -> String {
        "clients_disconnected".appending("-").appending(channel)
    }

    static func message(on channelId: String) -> String {
        "message".appending("-").appending(channelId)
    }
}
