//
//  MockSocketManager.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk
import SocketIO

class MockSocketManager: SocketManagerProtocol {
    var standardSocket: SocketProtocol
    
    init() {
        standardSocket = MockSocketClient()
    }
}
