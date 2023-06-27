//
//  SDKInfo.swift
//

import UIKit
import Foundation

public enum SDKInfo {
    /// Bundle with SDK plist
    public static var sdkBundle: [String: Any] {
        Bundle(for: MetaMaskSDK.self).infoDictionary ?? [:]
    }

    /// The version number of the SDK e.g `1.0.0`
    public static var version: String {
        sdkBundle["CFBundleShortVersionString"] as? String ?? ""
    }
    
    /// The bundle identifier of the dapp
    public static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? UUID().uuidString
    }
    
    /// The platform OS on which the SDK is run e.g `ios, ipados`
    public static var platform: String {
        UIDevice.current.systemName.lowercased()
    }
}
