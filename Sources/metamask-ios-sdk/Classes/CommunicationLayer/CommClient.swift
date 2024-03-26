//
//  CommClient.swift
//  metamask-ios-sdk
//

import Foundation

public typealias RequestJob = () -> Void

public protocol CommClient {
    
    var appMetadata: AppMetadata? { get set }
    var sessionDuration: TimeInterval { get set }
    
    var trackEvent: ((Event, [String: Any]) -> Void)? { get set }
    var handleResponse: (([String: Any]) -> Void)? { get set }
    
    func connect()
    func disconnect()
    func clearSession()
    func addRequest(_ job: @escaping RequestJob)
    func sendMessage(_ message: String, encrypt: Bool)
}

public extension CommClient {
    func originatorInfo() -> RequestInfo {
        let originatorInfo = OriginatorInfo(
            title: appMetadata?.name,
            url: appMetadata?.url,
            icon: appMetadata?.iconUrl ?? appMetadata?.base64Icon,
            platform: SDKInfo.platform,
            apiVersion: SDKInfo.version
        )

        return RequestInfo(
            type: "originator_info",
            originator: originatorInfo,
            originatorInfo: originatorInfo
        )
    }
}
