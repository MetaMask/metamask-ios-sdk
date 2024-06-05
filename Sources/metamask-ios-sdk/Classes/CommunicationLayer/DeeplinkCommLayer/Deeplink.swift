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
        case let (.mmsdk(messageLhs, pubkeyLhs, channelIdLhs), .mmsdk(messageRhs, pubkeyRhs, channelIdRhs)):
            return messageLhs == messageRhs && pubkeyLhs == pubkeyRhs && channelIdLhs == channelIdRhs
        case let (.connect(pubkeyLhs, channelIdLhs, requestLhs), .connect(pubkeyRhs, channelIdRhs, requestRhs)):
            return pubkeyLhs == pubkeyRhs && channelIdLhs == channelIdRhs && requestLhs == requestRhs
        default:
            return false
        }
    }
}
