//
//  SocketChannel.swift
//

import SocketIO
import Foundation

class SocketChannel {
    let socket: SocketIOClient
    private let socketManager: SocketManager

    init() {
        let url = URL(string: Endpoint.SOCKET_IO_SERVER)!
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

extension SocketChannel {
    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
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
