//
//  TimestampGenerator.swift
//  metamask-ios-sdk
//

import Foundation

public struct TimestampGenerator {
    public static func timestamp() -> String {
        let currentDate = Date()
        let salt = Int64(arc4random_uniform(100)) + 1
        let time = Int64(currentDate.timeIntervalSince1970 * 1000)
        let uniqueTime = salt + time
        return String(uniqueTime)
    }
}
