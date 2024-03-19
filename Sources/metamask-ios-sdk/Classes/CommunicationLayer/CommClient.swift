//
//  CommClient.swift
//  metamask-ios-sdk
//

import Foundation

protocol CommClient {
    func connect()
    func disconnect()
    func sendMessage(_ message: String, encrypted: Bool)
    func handleMessage(_ message: String)
}
