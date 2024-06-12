//
//  MockSocketChannel.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk
import SocketIO

class MockSocketChannel: SocketChannel {
    private var connected = false
    var lastEmittedEvent: String?
    var lastEmittedMessage: CodableData?
    var eventHandlers: [String: ([Any]) -> Void] = [:]
    
    override var isConnected: Bool {
        connected
    }
    
    override func connect() {
        connected = true
    }
    
    override func disconnect() {
        connected = false
    }
    
    override func on(_ event: SocketClientEvent, completion: @escaping ([Any]) -> Void) {
        eventHandlers[event.rawValue] = completion
    }
    
    override func on(_ event: String, completion: @escaping ([Any]) -> Void) {
        eventHandlers[event] = completion
    }
    
    override func emit(_ event: String, _ item: CodableData) {
        lastEmittedEvent = event
        lastEmittedMessage = item
    }
    
    func simulateEvent(_ event: String, data: [Any]) {
        eventHandlers[event]?(data)
    }
}
