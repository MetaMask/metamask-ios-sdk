//
//  OriginatorInfo.swift
//  metamask-ios-sdk
//

import Foundation

public struct OriginatorInfo: CodableData {
    public let title: String?
    public let url: String?
    public let icon: String?
    public let dappId: String?
    public let platform: String?
    public let apiVersion: String?

    public func socketRepresentation() -> NetworkData {
        [
            "title": title,
            "url": url,
            "icon": icon,
            "dappId": dappId,
            "platform": platform,
            "apiVersion": apiVersion
        ]
    }
}
