//
//  MetaMaskSDK.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import OSLog
import Foundation

public class MetaMaskSDK {
    public static var shared = MetaMaskSDK()
    private let connection = Connection(channelId: UUID().uuidString.lowercased())
    
    var url: String? {
        didSet {
            connection.url = url
        }
    }
    
    var name: String? {
        didSet {
            connection.name = name
        }
    }
    
    public var onClientsReady: ((RequestTask?) -> Void)? {
        didSet {
            connection.onClientsReady = onClientsReady
        }
    }
    
    public var isConnected: Bool {
        connection.connected
    }
    
    public func connect() {
        connection.connect()
    }
    
    public func openMetaMask() {
        connection.deeplinkToMetaMask()
    }
    
    public func disconnect() {
        connection.disconnect()
    }
    
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool) {
        connection.sendMessage(message, encrypt: encrypt)
    }
}
