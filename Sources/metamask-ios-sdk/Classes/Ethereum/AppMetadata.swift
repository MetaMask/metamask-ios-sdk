//
//  Dapp.swift
//

import Foundation

public struct AppMetadata {
    public let name: String
    public let url: String
    public let iconUrl: String?
    public let base64Icon: String?
    public let apiVersion: String?

    var platform: String = "ios"

    public init(name: String,
                url: String,
                iconUrl: String? = nil,
                base64Icon: String? = nil,
                apiVersion: String? = nil
    ) {
        self.name = name
        self.url = url
        self.iconUrl = iconUrl
        self.apiVersion = apiVersion
        self.base64Icon = base64Icon
    }
}
