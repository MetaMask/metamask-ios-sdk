//
//  DeeplinkClient.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation


public class DeeplinkClient {
    public var useDeeplinks: Bool = true
    
    private let appScheme = "metamaskdapp"
    private let session: SessionManager
    private var channelId: String = ""
    private let targetAppScheme: String
    private let targetAppUniversalLink: String
    
    private var _deeplinkUrl: String {
        useDeeplinks ? "\(targetAppScheme):/" : "\(targetAppUniversalLink)"
    }
    
    init(session: SessionManager, 
         targetAppScheme: String = "targeter",
         targetAppUniversalLink: String = "https://metamask.app.link"
    ) {
        self.session = session
        self.targetAppScheme = targetAppScheme
        self.targetAppUniversalLink = targetAppUniversalLink
        setupClient()
    }
    
    public func setupClient() {
        let sessionInfo = session.fetchSessionConfig()
        channelId = sessionInfo.0.sessionId
    }
    
    private func sendMessageToMetaMask(_ message: String) {
        let deeplink = "\(_deeplinkUrl)/\(message)"
        guard
            let urlString = deeplink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString)
        else { return }

        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
    
    public func sendMessage(deeplink: Deeplink) {
        switch deeplink {
        case .keyExchange(let type, let pubKey):
            var message = "\(Deeplink.keyExchange)?type=\(type)"
            if let pubkey = pubKey {
                message.append("&pubkey=\(pubkey)")
            }
            sendMessageToMetaMask(message)
        case .connect(_, let pubKey):
            let message = "\(Deeplink.connect)?appScheme=\(appScheme)&pubkey=\(pubKey)"
            sendMessageToMetaMask(message)
        case .message(let message, let pubKey):
            let message = "\(Deeplink.message)?message=\(message)&pubkey=\(pubKey)&channelId=\(channelId)"
            sendMessageToMetaMask(message)
        default: break
        }
    }
}

