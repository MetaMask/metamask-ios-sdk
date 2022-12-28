//
//  SDKInfo.swift
//

import Foundation

struct SDKInfo {
    /// Bundle SDK's plist
    static var sdkBundle: [String: Any] {
        Bundle(for: MMSDK.self).infoDictionary ?? [:]
    }
    
    /// The version number of the SDK e.g `1.0.0`
    static var version: String {
        sdkBundle["CFBundleShortVersionString"] as? String ?? ""
    }
}
