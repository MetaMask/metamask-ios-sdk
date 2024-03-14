//
//  DeeplinkManager.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

class DeeplinkManager {
    static func setAppScheme(_ scheme: String) {
        appScheme = scheme
    }
    
    private static var appScheme: String = ""
    
    static func getDeeplink(_ link: String) -> Deeplink {
        if appScheme.isEmpty {
            Logging.error("DeeplinkManager:: App scheme not set")
            return .invalid
        }
        
        guard let url = URL(string: link) else {
            Logging.error("DeeplinkManager:: Deeplink has invalid url")
            return .invalid
        }
        
        guard url.scheme == appScheme else {
            Logging.error("DeeplinkManager:: Deeplink is missing scheme")
            return .invalid
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            Logging.error("DeeplinkManager:: Deeplink missing components")
            return .invalid
        }
        
        guard let action = components.host else {
            Logging.error("DeeplinkManager:: Deeplink missing action")
            return .invalid
        }
        
        if action == Deeplink.keyExchange {
            guard let step = components.queryItems?.first(where: { $0.name == "step" })?.value else {
                Logging.error("DeeplinkManager:: Deeplink missing key exchange step")
                return .invalid
            }
            
            let publicKey: String? = components.queryItems?.first(where: { $0.name == "pubkey" })?.value
            return .keyExchange(step, publicKey)
        }
        
        if action == Deeplink.message {
            guard let message = components.queryItems?.first(where: { $0.name == "message" })?.value else {
                Logging.error("DeeplinkManager:: Deeplink missing message")
                return .invalid
            }
            return .message(message)
        }

        return .invalid
    }
}
