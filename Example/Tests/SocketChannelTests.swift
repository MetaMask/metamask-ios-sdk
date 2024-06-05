//
//  SocketChannelTests.swift
//  metamask-ios-sdk_Tests
//

import XCTest
@testable import metamask_ios_sdk

class SocketChannelTests: XCTestCase {
    var socketChannel: SocketChannel!
    var mockSocket: MockSocket!
    var mockSocketManager: MockSocketManager!

    override func setUp() {
        super.setUp()
        mockSocketManager = MockSocketManager()
        socketChannel = SocketChannel(url: "http://mockurl.com")
        mockSocket = mockSocketManager.standardSocket as? MockSocket
        socketChannel.socket = mockSocket
        socketChannel.socketManager = mockSocketManager
    }

    func testNetworkUrl() {
        XCTAssertEqual(socketChannel.networkUrl, "http://mockurl.com")

        socketChannel.networkUrl = "http://newurl.com"
        XCTAssertEqual(socketChannel.networkUrl, "http://newurl.com")
    }

    func testIsConnected() {
        mockSocket.status = .connected
        XCTAssertTrue(socketChannel.isConnected)

        mockSocket.status = .disconnected
        XCTAssertFalse(socketChannel.isConnected)
    }

    func testConnect() {
        socketChannel.connect()
        XCTAssertTrue(mockSocket.connectCalled)
    }

    func testDisconnect() {
        socketChannel.disconnect()
        XCTAssertTrue(mockSocket.disconnectCalled)
    }

    func testTearDown() {
        socketChannel.tearDown()
    }

    func testOnClientEvent() {
        socketChannel.on(.connect) { _ in }

        XCTAssertTrue(mockSocket.called(.connect))
    }

    func testOnStringEvent() {
        socketChannel.on("testEvent") { _ in }

        XCTAssertTrue(mockSocket.called("testEvent"))
    }

    func testEmit() {
        socketChannel.emit("testEvent", "testData")
        XCTAssertTrue(mockSocket.emitCalled)
    }
}
