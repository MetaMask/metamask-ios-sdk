//
//  Logging.swift
//

import OSLog
import Foundation

public class Logging {
    public static func log(_ message: String) {
        Logger().log("mmsdk| \(message)")
    }

    public static func error(_ error: String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger().log(
            level: .error,
            "\n============\nmmsdk| Error: \(error)\nFunc: \(function)\nFile: \(fileName(from: file))\nLine: \(line)\n============\n"
        )
    }

    public static func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        Logger().log(level: .error, "\n============\nmmsdk| Error \nFunc: \(function)\nFile: \(fileName(from: file))\nLine: \(line)\nError: \(error.localizedDescription)\n============\n")
    }

    private static func fileName(from path: String) -> String {
        path.components(separatedBy: "/").last ?? ""
    }
}
