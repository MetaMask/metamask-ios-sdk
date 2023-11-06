//
//  SocketChannel.swift
//

import SocketIO
import Foundation

class SocketChannel {
    var serverUrl: String {
        get {
            Endpoint.SERVER_URL
        } set {
            Endpoint.SERVER_URL = newValue
            configureSocket(url: newValue)
        }
    }

    var socket: SocketIOClient!
    private var socketManager: SocketManager!
    
    var isConnected: Bool {
        socket.status == .connected
    }

    init() {
        configureSocket(url: Endpoint.SERVER_URL)
    }

    func configureSocket(url: String) {
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
                .log(false),
                options
            ]
        )
        socket = socketManager.defaultSocket
    }
}

// MARK: Session

extension SocketChannel {
    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }
    
    func terminateHandlers() {
        socket.removeAllHandlers()
    }
}

// MARK: Events

extension SocketChannel {
    func on(clientEvent: SocketClientEvent, completion: @escaping ([Any]) -> Void) {
        socket.on(clientEvent: clientEvent, callback: { data, _ in
            DispatchQueue.main.async {
                completion(data)
            }
        })
    }

    func on(_ event: String, completion: @escaping ([Any]) -> Void) {
        socket.on(event, callback: { data, _ in
            DispatchQueue.main.async {
                completion(data)
            }
        })
    }

    func emit(_ event: String, _ item: SocketData) {
        socket.emit(event, item)
    }
}
