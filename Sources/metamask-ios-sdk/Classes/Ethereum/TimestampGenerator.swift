//
//  TimestampGenerator.swift
//  metamask-ios-sdk
//

import Foundation

public struct TimestampGenerator {
    public static func timestamp() -> String {
        let currentDate = Date()
        return String(Int64(currentDate.timeIntervalSince1970 * 1000))
    }
}
