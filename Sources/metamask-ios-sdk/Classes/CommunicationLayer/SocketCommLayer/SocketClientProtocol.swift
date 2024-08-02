//
//  SocketProtocol.swift
//

import Foundation
import SocketIO

protocol SocketProtocol {
    var status: SocketIOStatus { get }
    func connect(withPayload payload: [String: Any]?)
    func disconnect()
    func emit(_ event: String, _ items: SocketData..., completion: (() -> Void)?)
    @discardableResult
    func on(clientEvent event: SocketClientEvent, callback: @escaping ([Any], SocketAckEmitter) -> Void) -> UUID
    @discardableResult
    func on(_ event: String, callback: @escaping ([Any], SocketAckEmitter) -> Void) -> UUID
    func removeAllHandlers()
}

protocol SocketManagerProtocol {
    var standardSocket: SocketProtocol { get }
}

extension SocketIOClient: SocketProtocol { }

extension SocketManager: SocketManagerProtocol {
    var standardSocket: SocketProtocol {
        self.defaultSocket as SocketProtocol
    }
}
