//
//  SocketChannel.swift
//

import SocketIO
import Foundation

public class Channel: CommunicationChannel {
    public typealias ChannelData = SocketData
    public typealias EventType = SocketClientEvent
    
    public var networkUrl: String {
        get {
            _networkUrl
        } set {
            _networkUrl = newValue
        }
    }
    
    public var isConnected: Bool {
        socket.status == .connected
    }
    
    private var _networkUrl: String

    private var socket: SocketIOClient!
    private var socketManager: SocketManager!
    

    public init(url: String = Endpoint.SERVER_URL) {
        _networkUrl = url
        configure(url: url)
    }

    private func configure(url: String) {
        guard let url = URL(string: url) else {
            Logging.error("Socket url is invalid")
            return
        }

        let options: SocketIOClientOption = .extraHeaders(
            [
                "User-Agent": "SocketIOClient"
            ]
        )

        socketManager = SocketManager(
            socketURL: url,
            config: [
                .log(true),
                options
            ]
        )
        socket = socketManager.defaultSocket
    }
}

// MARK: Session

extension Channel {
    public func connect() {
        socket.connect()
    }

    public func disconnect() {
        socket.disconnect()
    }
    
    public func tearDown() {
        socket.removeAllHandlers()
    }
}

// MARK: Events

extension Channel {
    public func on(_ event: SocketClientEvent, completion: @escaping ([Any]) -> Void) {
        socket.on(clientEvent: event, callback: { data, _ in
            DispatchQueue.main.async {
                completion(data)
            }
        })
    }

    public func on(_ event: String, completion: @escaping ([Any]) -> Void) {
        socket.on(event, callback: { data, _ in
            DispatchQueue.main.async {
                completion(data)
            }
        })
    }

    public func emit(_ event: String, _ item: SocketData) {
        socket.emit(event, item)
    }
}
