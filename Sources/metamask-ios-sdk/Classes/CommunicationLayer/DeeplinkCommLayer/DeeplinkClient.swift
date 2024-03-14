//
//  DeeplinkClient.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation


public class DeeplinkClient {
    public static var useDeeplinks: Bool = true
    
    private static var _deeplinkUrl: String {
        useDeeplinks ? "metamask:/" : "https://metamask.app.link"
    }

//    var deeplinkUrl: String {
//        "\(_deeplinkUrl)/connect?channelId="
//            + channelId
//            + "&comm=socket"
//            + "&pubkey="
//            + keyExchange.pubkey
//    }
    
    private static func deeplinkToMetaMask(_ path: String) {
        let deeplink = "\(_deeplinkUrl)/\(path)"
        guard
            let urlString = deeplink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString)
        else { return }

        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
    
    public static func sendMessage(deeplink: Deeplink, channelId: String) {
        switch deeplink {
        case .keyExchange(let type, let pubKey):
            var path = "\(Deeplink.keyExchange)?type=\(type)"
            if let pubkey = pubKey {
                path.append("&pubkey=\(pubkey)")
            }
            deeplinkToMetaMask(path)
        case .connect(let pubKey):
            let path = "\(Deeplink.connect)?pubkey=\(pubKey)"
            deeplinkToMetaMask(path)
        case .message(let message):
            let path = "\(Deeplink.message)?message=\(message)&channelId=\(channelId)"
            deeplinkToMetaMask(path)
        default: break
        }
    }
}

