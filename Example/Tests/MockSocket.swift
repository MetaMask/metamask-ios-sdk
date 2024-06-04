//
//  MockSocket.swift
//  metamask-ios-sdk_Tests
//

import Foundation
@testable import metamask_ios_sdk
import SocketIO

class MockSocket: SocketProtocol {
    var status: SocketIOStatus = .notConnected
    var connectCalled = false
    var disconnectCalled = false
    var emitCalled = false
    var onCalled = false
    
    var eventCallbacks: [String: ([Any], SocketAckEmitter) -> Void] = [:]
    var clientEventCallbacks: [SocketClientEvent: ([Any], SocketAckEmitter) -> Void] = [:]
    
    func connect(withPayload payload: [String: Any]?) {
        connectCalled = true
    }
    
    func disconnect() {
        disconnectCalled = true
    }
    
    func emit(_ event: String, _ items: SocketData..., completion: (() -> ())?) {
        emitCalled = true
    }
    
    @discardableResult
    func on(clientEvent event: SocketClientEvent, callback: @escaping ([Any], SocketAckEmitter) -> ()) -> UUID {
        onCalled = true
        clientEventCallbacks[event] = callback
        return UUID()
    }
    
    @discardableResult
    func on(_ event: String, callback: @escaping ([Any], SocketAckEmitter) -> Void) -> UUID {
        onCalled = true
        eventCallbacks[event] = callback
        return UUID()
    }
    
    func called(_ event: String) -> Bool {
        eventCallbacks[event] != nil
    }
    
    func called(_ event: SocketClientEvent) -> Bool {
        clientEventCallbacks[event] != nil
    }
    
    func removeAllHandlers() {
        eventCallbacks.removeAll()
        clientEventCallbacks.removeAll()
    }
}

