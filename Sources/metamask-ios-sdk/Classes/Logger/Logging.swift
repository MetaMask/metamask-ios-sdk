//
//  Logging.swift
//

import OSLog
import Foundation

class Logging {
    static func log(_ message: String) {
        Logger().log("mmsdk| \(message)")
    }

    static func error(_ error: String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger().log(
            level: .error,
            "\n============\nmmsdk| Error: \(error)\nFunc: \(function)\nFile: \(fileName(from: file))\nLine: \(line)\n============\n"
        )
    }

    static func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        Logger().log(level: .error, "\n============\nmmsdk| Error \nFunc: \(function)\nFile: \(fileName(from: file))\nLine: \(line)\nError: \(error.localizedDescription)\n============\n")
    }

    static func fileName(from path: String) -> String {
        path.components(separatedBy: "/").last ?? ""
    }
}
