//
//  CommClient.swift
//  metamask-ios-sdk
//

import Foundation

public typealias RequestJob = () -> Void

protocol CommClient {
    var commLayer: CommLayer { get }
    var appMetadata: AppMetadata? { get set }
    var trackEvent: ((Event) -> Void)? { get }
    
    var handleEvent: (([String: Any]) -> Void)? { get }
    var handleResponse: ((String, [String: Any]) -> Void)? { get }
    
    func connect()
    func disconnect()
    func terminateConnection()
    func addRequest(_ job: @escaping RequestJob)
    func sendMessage(_ message: String, encrypted: Bool)
}

extension CommClient {
    func sendOriginatorInfo() {
        let originatorInfo = OriginatorInfo(
            title: appMetadata?.name,
            url: appMetadata?.url,
            icon: appMetadata?.iconUrl ?? appMetadata?.base64Icon,
            platform: SDKInfo.platform,
            apiVersion: SDKInfo.version
        )

        let requestInfo = RequestInfo(
            type: "originator_info",
            originator: originatorInfo,
            originatorInfo: originatorInfo
        )

        sendMessage(requestInfo, encrypt: true)
    }
}
