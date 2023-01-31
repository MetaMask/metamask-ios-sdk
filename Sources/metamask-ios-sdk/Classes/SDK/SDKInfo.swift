//
//  SDKInfo.swift
//

import Foundation

struct SDKInfo {
    /// Bundle with SDK plist
    static var sdkBundle: [String: Any] {
        Bundle(for: MetaMaskSDK.self).infoDictionary ?? [:]
    }

    /// The version number of the SDK e.g `1.0.0`
    static var version: String {
        sdkBundle["CFBundleShortVersionString"] as? String ?? ""
    }
}
