//
//  SDKInfo.swift
//

import Foundation

struct SDKInfo {
    /// Bundle with access to the SDK's bundle directory
    static var sdkBundle: [String: Any] {
        Bundle(for: MMSDK.self).infoDictionary ?? [:]
    }
    
    /// The version number of the SDK e.g `1.0.0`
    static var version: String {
        sdkBundle["CFBundleShortVersionString"] as? String ?? ""
    }
}
