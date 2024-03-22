//
//  DeeplinkClient.swift
//  metamask-ios-sdk
//

import UIKit
import Foundation


public class DeeplinkClient: CommClient {
    public var useDeeplinks: Bool = true
    
    private let schema = "metamaskdapp"
    private let session: SessionManager
    private var channelId: String = ""
    private let targetAppSchema: String
    
    var appMetadata: AppMetadata?
    var trackEvent: ((Event) -> Void)?
    var handleEvent: (([String: Any]) -> Void)?
    var handleResponse: ((String, [String: Any]) -> Void)?
    
    private let keyExchange: KeyExchange
    private let deeplinkManager: DeeplinkManager
    
    var requestJobs: [RequestJob] = []
    
    init(session: SessionManager,
         keyExchange: KeyExchange,
         deeplinkManager: DeeplinkManager,
         targetAppSchema: String = "targeter"
    ) {
        self.session = session
        self.keyExchange = keyExchange
        self.deeplinkManager = deeplinkManager
        self.targetAppSchema = targetAppSchema
        self.deeplinkManager.onReceiveMessage = handleMessage
        self.deeplinkManager.onReceivePublicKey = keyExchange.setTheirPublicKey
        self.deeplinkManager.decryptMessage = keyExchange.decryptMessage
        setupClient()
    }
    
    private func setupClient() {
        let sessionInfo = session.fetchSessionConfig()
        channelId = sessionInfo.0.sessionId
    }
    
    private func sendMessage(_ message: String) {
        let deeplink = "\(targetAppSchema)://\(message)"
        guard
            let urlString = deeplink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString)
        else { return }

        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
    
    public func handleUrl(_ url: URL) {
        deeplinkManager.handleUrl(url)
    }
    
    func sendMessage(_ deeplink: Deeplink) {
        switch deeplink {
        case .connect(let schema, let pubkey, let channelId):
            let message = "connect?schema=\(schema)&pubkey=\(pubkey)&channelId=\(channelId)&comm=deeplinking"
            sendMessage(message)
        case .mmsdk(let message, let pubkey):
            let message = "mmsdk?message=\(message)&pubkey=\(String(describing: pubkey))"
            sendMessage(message)
        }
    }
    
    public func connect() {
        sendMessage(.connect(
            schema: schema,
            pubkey: keyExchange.pubkey,
            channelId: channelId))
    }
}

extension DeeplinkClient {
    func terminateConnection() {}
    
    var commLayer: CommLayer { .deeplinking }
    
    func disconnect() {}
    
    func addRequest(_ job: @escaping RequestJob) {
        requestJobs.append(job)
    }
    
    func sendMessage(_ message: String, encrypted: Bool) {
        let deeplink: Deeplink = .mmsdk(message: message, pubkey: keyExchange.pubkey)
        sendMessage(deeplink)
    }
    
    func handleMessage(_ message: String) {
        do {
            let json: [String: Any] = try JSONSerialization.jsonObject(
                with: Data(message.utf8),
                options: []
            )
                as? [String: Any] ?? [:]
            
            guard let data = json["data"] as? [String: Any] else {
                Logging.log("DeeplinkClient:: Ignoring response \(json)")
                return
            }
            
            if let id = data["id"] {
                if let identifier: Int64 = id as? Int64 {
                    let id: String = String(identifier)
                    handleResponse?(id, data)
                } else if let identifier: String = id as? String {
                    handleResponse?(identifier, data)
                }
            } else {
                handleEvent?(data)
            }
        } catch {
            Logging.error("DeeplinkClient:: Could not deserialise message to json \(message)")
        }
    }
}

