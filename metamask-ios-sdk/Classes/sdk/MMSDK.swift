//
//  MMSDK.swift
//

import OSLog
import Foundation
import Combine

public class MMSDK {
    private let connection: Connection
    
    /// In debug mode we track three events: connection request, connected, disconnected, otherwise no tracking
    /// - Parameter debug: Flag indicating whether the SDK may track events or not
    public convenience init(debug: Bool = true) {
        self.init(
            channelId: UUID().uuidString.lowercased(),
            tracker: debug ? Analytics.debug : Analytics.release)
    }
    
    init(channelId: String, tracker: Tracking) {
        self.connection = Connection(
            channelId: channelId,
            tracker: tracker)
    }
    
    var dappUrl: String? {
        didSet {
            connection.url = dappUrl
        }
    }
    
    var dappName: String? {
        didSet {
            connection.name = dappName
        }
    }
    
    var onClientsReady: (() -> Void)? {
        didSet {
            connection.onClientsReady = onClientsReady
        }
    }
    
    var isConnected: Bool {
        connection.connected
    }
    
    func connect() {
        connection.connect()
    }
    
    func disconnect() {
        connection.disconnect()
    }
    
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool) {
        connection.sendMessage(message, encrypt: encrypt)
    }
}
