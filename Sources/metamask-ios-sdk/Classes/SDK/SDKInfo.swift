//
//  SDKInfo.swift
//

import UIKit
import Foundation

enum SDKInfo {
    /// Bundle with SDK plist
    static var sdkBundle: [String: Any] {
        Bundle(for: MetaMaskSDK.self).infoDictionary ?? [:]
    }

    /// The version number of the SDK e.g `1.0.0`
    static var version: String {
        sdkBundle["CFBundleShortVersionString"] as? String ?? ""
    }
    
    /// The platform OS on which the SDK is run e.g `iOS, iPadOS`
    static var platform: String {
        UIDevice.current.systemName
    }
}
