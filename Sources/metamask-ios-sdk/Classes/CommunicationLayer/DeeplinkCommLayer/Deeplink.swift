//
//  Deeplink.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

public enum Deeplink {
    case mmsdk(message: String, pubkey: String)
    case connect(schema: String, pubkey: String, channelId: String)
    
    static let mmsdk = "mmsdk"
    static let connect = "connect"
}
