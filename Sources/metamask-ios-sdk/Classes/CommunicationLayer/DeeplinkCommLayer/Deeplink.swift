//
//  Deeplink.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

public enum Deeplink: Equatable {
    case mmsdk(message: String, pubkey: String?, channelId: String?)
    case connect(pubkey: String?, channelId: String, request: String?)
    
    static let mmsdk = "mmsdk"
    static let connect = "connect"

        public static func == (lhs: Deeplink, rhs: Deeplink) -> Bool {
        switch (lhs, rhs) {
        case let (.mmsdk(message1, pubkey1, channelId1), .mmsdk(message2, pubkey2, channelId2)):
            return message1 == message2 && pubkey1 == pubkey2 && channelId1 == channelId2
        case let (.connect(pubkey1, channelId1, request1), .connect(pubkey2, channelId2, request2)):
            return pubkey1 == pubkey2 && channelId1 == channelId2 && request1 == request2
        default:
            return false
        }
    }
}
