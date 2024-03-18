//
//  DeeplinkManager.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

public class DeeplinkManager {
    public static func setAppScheme(_ scheme: String) {
        appScheme = scheme
    }
    
    static let keyExchange = KeyExchange()
    
    private static var appScheme: String = "metamaskdapp"
    
    public static func handleDeeplink(_ link: URL) -> Deeplink? {
        handleDeeplink(link.absoluteString)
    }
    
    public static func handleDeeplink(_ link: String) -> Deeplink? {
        let deeplink = getDeeplink(link)
        
        switch deeplink {
        case .keyExchange(let type, let pubkey):
            print("DeeplinkManager:: key exchange: \(type), pubkey: \(pubkey)")
            let keyExchangetype = KeyExchangeType(rawValue: type)!
            if let nextStep = keyExchange.nextStep(keyExchangetype) {
                return .keyExchange(nextStep.rawValue, keyExchange.pubkey)
            }
            return .message("Wallet info: metamask ios sdk dapp")
        case .connect(let otherPubKey):
            print("DeeplinkManager:: connect otherPubKey: \(otherPubKey)")
            return .keyExchange(KeyExchangeType.syn.rawValue, "mypubkey")
        case .message(let message):
            print("DeeplinkManager:: message: \(message)")
            return nil
            //return .message("Got your message!")
        case .invalid:
            print("DeeplinkManager:: Invalid deeplink: \(link)")
            return nil
        }
    }
    
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
        
        if action == Deeplink.connect {
            guard let publicKey: String = components.queryItems?.first(where: { $0.name == "pubkey" })?.value else {
                Logging.error("DeeplinkManager:: Connect step missing other party's public key")
                return .invalid
            }
            return .connect(publicKey)
            
        } else if action == Deeplink.keyExchange {
            guard let step = components.queryItems?.first(where: { $0.name == "type" })?.value else {
                Logging.error("DeeplinkManager:: Deeplink missing key exchange type")
                return .invalid
            }
            
            let publicKey: String? = components.queryItems?.first(where: { $0.name == "pubkey" })?.value
            return .keyExchange(step, publicKey)
            
        } else if action == Deeplink.message {
            guard let message = components.queryItems?.first(where: { $0.name == "message" })?.value else {
                Logging.error("DeeplinkManager:: Deeplink missing message")
                return .invalid
            }
            return .message(message)
        }

        return .invalid
    }
}
