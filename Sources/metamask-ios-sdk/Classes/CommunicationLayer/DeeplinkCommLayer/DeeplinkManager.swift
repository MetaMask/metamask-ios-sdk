//
//  DeeplinkManager.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

public class DeeplinkManager {
    var onReceiveMessage: ((String) -> Void)?
    
    public func handleUrl(_ url: URL)  {
        handleUrl(url.absoluteString)
    }
    
    public func handleUrl(_ url: String)  {
        let deeplink = getDeeplink(url)
        
        switch deeplink {
        case .mmsdk(let message, _, _):
            let base64Decoded = message.base64Decode() ?? ""
            
            onReceiveMessage?(base64Decoded)
            
        default:
            Logging.error("DeeplinkManager:: ignoring url \(url)")
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
            guard let channelId: String = components.queryItems?.first(where: { $0.name == "channelId" })?.value else {
                Logging.error("DeeplinkManager:: Connect step missing channelId")
                return nil
            }
            return .connect(pubkey: nil, channelId: channelId, request: nil)
            
        } else if action == Deeplink.mmsdk {
            guard let message = components.queryItems?.first(where: { $0.name == "message" })?.value else {
                Logging.error("DeeplinkManager:: Deeplink missing message")
                return nil
            }

            return .mmsdk(message: message, pubkey: nil, channelId: nil)
        }

        return nil
    }
}
