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
    
    public func connect() {
        connection.connect()
    }
    
    public func openMetaMask() {
        connection.deeplinkToMetaMask()
    }
    
    public func disconnect() {
        connection.disconnect()
    }
}
