//
//  Deeplink.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

public enum Deeplink {
    case keyExchange(type: String, publicKey: String?)
    case message(String, publicKey: String)
    case connect(appScheme: String? = nil, publicKey: String)
    case invalid
    
    static let keyExchange = "key-exchange"
    static let message = "message"
    static let connect = "connect"
}
