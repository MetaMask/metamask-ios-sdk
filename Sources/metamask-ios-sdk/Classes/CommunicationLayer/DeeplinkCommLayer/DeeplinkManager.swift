//
//  DeeplinkManager.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

public class DeeplinkManager {
    var onReceivePublicKey: ((String) -> Void)?
    var onReceiveMessage: ((String) -> Void)?
    var decryptMessage: ((String) throws -> String?)?
    
    private var connected = false
    
    public func handleUrl(_ url: URL)  {
        handleUrl(url.absoluteString)
    }
    
    public func handleUrl(_ url: String)  {
        let deeplink = getDeeplink(url)
        
        switch deeplink {
        case .connect(let scheme, let pubkey, let channelId):
            Logging.log("DeeplinkManager:: connect from \(scheme) pubkey: \(pubkey), channelId: \(channelId)")
            onReceivePublicKey?(pubkey)
        case .mmsdk(let message, let pubkey):
            Logging.log("DeeplinkManager:: message: \(message), pubkey: \(pubkey)")
            onReceivePublicKey?(pubkey)
            
            if !connected {
                connected = true
            }
            
            if let decryptedMsg: String = try? decryptMessage?(message) {
                Logging.log("DeeplinkManager:: decrypted message: \(decryptedMsg)")
                onReceiveMessage?(decryptedMsg)
            } else {
                Logging.error("DeeplinkManager:: Could not decrypt message: \(message)")
            }
            
        case .none:
            Logging.error("DeeplinkManager:: invalid url \(url)")
        }
    }
    
    func getDeeplink(_ link: String) -> Deeplink? {
        
        guard let url = URL(string: link) else {
            Logging.error("DeeplinkManager:: Deeplink has invalid url")
            return nil
        }
        
        guard let _ = url.scheme else {
            Logging.error("DeeplinkManager:: Deeplink is missing scheme")
            return nil
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            Logging.error("DeeplinkManager:: Deeplink missing components")
            return nil
        }
        
        guard let action = components.host else {
            Logging.error("DeeplinkManager:: Deeplink missing action")
            return nil
        }
        
        if action == Deeplink.connect {
            guard let scheme: String = components.queryItems?.first(where: { $0.name == "scheme" })?.value else {
                Logging.error("DeeplinkManager:: Connect missing scheme")
                return nil
            }
            
            guard let pubkey: String = components.queryItems?.first(where: { $0.name == "pubkey" })?.value else {
                Logging.error("DeeplinkManager:: Connect step missing other party's public key")
                return nil
            }
            
            guard let channelId: String = components.queryItems?.first(where: { $0.name == "channelId" })?.value else {
                Logging.error("DeeplinkManager:: Connect step missing channelId")
                return nil
            }
            return .connect(scheme: scheme, pubkey: pubkey, channelId: channelId)
            
        } else if action == Deeplink.mmsdk {
            guard let message = components.queryItems?.first(where: { $0.name == "message" })?.value else {
                Logging.error("DeeplinkManager:: Deeplink missing message")
                return nil
            }
            guard let pubkey = components.queryItems?.first(where: { $0.name == "pubkey" })?.value else {
                Logging.error("DeeplinkManager:: Deeplink missing pubkey")
                return nil
            }
            return .mmsdk(message: message, pubkey: pubkey)
        }

        return nil
    }
}
