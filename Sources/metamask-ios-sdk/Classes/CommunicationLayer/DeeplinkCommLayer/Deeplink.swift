//
//  Deeplink.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

public enum Deeplink {
    case keyExchange(String, String?)
    case message(String)
    case connect(String)
    case invalid
    
    static let keyExchange = "key-exchange"
    static let message = "message"
    static let connect = "connect"
}
