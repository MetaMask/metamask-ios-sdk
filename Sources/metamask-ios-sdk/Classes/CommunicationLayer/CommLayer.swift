//
//  CommLayer.swift
//  metamask-ios-sdk
//

import Foundation

public enum Transport: CaseIterable, Identifiable, Hashable {
    case socket
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
