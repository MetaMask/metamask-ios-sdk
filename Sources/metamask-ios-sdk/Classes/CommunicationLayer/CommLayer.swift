//
//  CommLayer.swift
//  metamask-ios-sdk
//

import Foundation

/**
 An enum representing the communication types supported for communication with MetaMask wallet
 **/
public enum Transport: CaseIterable, Identifiable, Hashable {
    /// Uses socket.io as a transport mechanism
    case socket
    /// Uses deeplinking as transport mechanism. Recommended. Requires setting URI scheme
    case deeplinking(dappScheme: String)

    public var id: String {
        switch self {
        case .socket:
            return "socket"
        case .deeplinking(let dappScheme):
            return "deeplinking_\(dappScheme)"
        }
    }

    public static var allCases: [Transport] {
        [.socket, .deeplinking(dappScheme: "")]
    }

    public var name: String {
        switch self {
        case .socket: return "Socket"
        case .deeplinking: return "Deeplinking"
        }
    }
}
