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
    private let connection: Connection!
    
    private init () {
        self.connection = Connection(channelId: UUID().uuidString)
    }
    
    public func connect() {
        connection.connect()
        print("Connect via: \(connection.qrCodeUrl)")
    }
    
    public func disconnect() {
        connection.disconnect()
    }
}
