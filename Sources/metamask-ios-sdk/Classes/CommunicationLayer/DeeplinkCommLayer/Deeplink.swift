//
//  Deeplink.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

public enum Deeplink {
    case mmsdk(message: String, pubkey: String?, channelId: String?)
    case connect(pubkey: String?, channelId: String)
    case connectWith(pubkey: String?, channelId: String, request: String)
    
    static let mmsdk = "mmsdk"
    static let connect = "connect"
}
