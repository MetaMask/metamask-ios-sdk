//
//  Logging.swift
//

import OSLog
import Foundation

class Logging {
    static func log(_ message: String) {
        Logger().log("mmsdk| \(message)")
    }

    static func error(_ error: String) {
        Logger().log(level: .error, "mmsdk| Error: \(error)")
    }

    static func error(_ error: Error) {
        Logger().log(level: .error, "mmsdk| Error: \(error.localizedDescription)")
    }
}
