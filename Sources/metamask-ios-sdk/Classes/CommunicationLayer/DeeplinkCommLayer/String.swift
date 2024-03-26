//
//  String.swift
//  metamask-ios-sdk

import Foundation

extension String {
    func trimEscapingChars() -> Self {
        var unescapedString = replacingOccurrences(of: #"\""#, with: "\"")
        if unescapedString.hasPrefix("\"") && unescapedString.hasSuffix("\"") {
            unescapedString.removeFirst()
            unescapedString.removeLast()
        }
        return unescapedString
    }
}
