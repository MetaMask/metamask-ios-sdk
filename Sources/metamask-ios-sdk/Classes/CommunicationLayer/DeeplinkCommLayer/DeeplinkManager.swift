//
//  DeeplinkManager.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation

public class DeeplinkManager {
    
    let keyExchange: KeyExchange
    let deeplinkClient: DeeplinkClient
    private let skipHandshake: Bool
    
    init(deeplinkClient: DeeplinkClient,
         keyExchange: KeyExchange = KeyExchange(),
         skipHandshake: Bool = true
    ) {
        self.keyExchange = keyExchange
        self.skipHandshake = skipHandshake
        self.deeplinkClient = deeplinkClient
    }
    
    public func handleUrl(_ url: URL) {
        handleUrl(url.absoluteString)
    }
    
    public func handleUrl(_ url: String) {
        let deeplink = getDeeplink(url)
        var response: Deeplink?
        
        switch deeplink {
        case .keyExchange(let type, let theirPublicKey):
            print("DeeplinkManager:: key exchange: \(type), pubkey: \(theirPublicKey)")
            if let senderPubKey = theirPublicKey {
                keyExchange.setTheirPublicKey(senderPubKey)
            }
            let keyExchangetype = KeyExchangeType(rawValue: type)!
            let keyExchangeMessage = KeyExchangeMessage(type: keyExchangetype, pubkey: theirPublicKey)
            
            if let nextKeyExchangeMessage = keyExchange.nextMessage(keyExchangeMessage) {
                response = .keyExchange(type: nextKeyExchangeMessage.type.rawValue, publicKey: keyExchange.pubkey)
            } else {
                let msg: String = (try? keyExchange.encryptMessage("Wallet 7.15.0")) ?? "Something went wrong"
                response = .message(msg, publicKey: keyExchange.pubkey)
            }
        case .connect(_, let theirPublicKey):
            print("DeeplinkManager:: connect otherPubKey: \(theirPublicKey)")
            keyExchange.setTheirPublicKey(theirPublicKey)
            
            if skipHandshake {
                let msg: String = (try? keyExchange.encryptMessage("Wallet 7.15.0")) ?? "Something went wrong"
                response = .message(msg, publicKey: keyExchange.pubkey)
            } else {
                response = .keyExchange(type: KeyExchangeType.syn.rawValue, publicKey: keyExchange.pubkey)
            }
        case .message(let message, let theirPublicKey):
            print("DeeplinkManager:: message: \(message)")
            keyExchange.setTheirPublicKey(theirPublicKey)
            let decryptedMsg: String = (try? keyExchange.decryptMessage(message)) ?? "Could not decrypt message"
            Logging.log("DeeplinkManager:: decrypted message: \(decryptedMsg)")
            //return .message("Got your message!")
        case .invalid:
            print("DeeplinkManager:: Invalid deeplink: \(link)")
        }
        
        if let message = response {
            deeplinkClient.sendMessage(deeplink: message)
        }
    }
    
    func getDeeplink(_ link: String) -> Deeplink {
        
        guard let url = URL(string: link) else {
            Logging.error("DeeplinkManager:: Deeplink has invalid url")
            return .invalid
        }
        
        guard let _ = url.scheme else {
            print("DeeplinkManager:: Deeplink is missing scheme")
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
            guard let appScheme: String = components.queryItems?.first(where: { $0.name == "appScheme" })?.value else {
                print("DeeplinkManager:: Connect missing appScheme")
                return .invalid
            }
            
            guard let theirPublicKey: String = components.queryItems?.first(where: { $0.name == "pubkey" })?.value else {
                print("DeeplinkManager:: Connect step missing other party's public key")
                return .invalid
            }
            return .connect(appScheme: appScheme, publicKey: theirPublicKey)
            
        } else if action == Deeplink.keyExchange {
            guard let type = components.queryItems?.first(where: { $0.name == "type" })?.value else {
                Logging.error("DeeplinkManager:: Deeplink missing key exchange type")
                return .invalid
            }
            
            let theirPublicKey: String? = components.queryItems?.first(where: { $0.name == "pubkey" })?.value
            return .keyExchange(type: type, publicKey: theirPublicKey)
            
        } else if action == Deeplink.message {
            guard let message = components.queryItems?.first(where: { $0.name == "message" })?.value else {
                Logging.error("DeeplinkManager:: Deeplink missing message")
                return .invalid
            }
            guard let pubkey = components.queryItems?.first(where: { $0.name == "pubkey" })?.value else {
                print("DeeplinkManager:: Deeplink missing pubkey")
                return .invalid
            }
            return .message(message, publicKey: pubkey)
        }

        return .invalid
    }
    
    public func connect() {
        sendMessage(deeplink: .connect(publicKey: keyExchange.pubkey))
    }
    
    public func sendMessage(deeplink: Deeplink) {
        deeplinkClient.sendMessage(deeplink: deeplink)
    }
}
