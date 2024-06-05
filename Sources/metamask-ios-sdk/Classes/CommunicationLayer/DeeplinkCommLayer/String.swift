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

func json(from value: Any) -> String? {
    // Recursive function to decode nested JSON strings
    func decodeNestedJson(_ value: Any) -> Any {
        if let arrayValue = value as? [Any] {
            // If it's an array, recursively decode each element
            return arrayValue.map { decodeNestedJson($0) }
        } else if let dictValue = value as? [String: Any] {
            // If it's a dictionary, recursively decode each value
            var decodedDict = [String: Any]()
            for (key, value) in dictValue {
                decodedDict[key] = decodeNestedJson(value)
            }
            return decodedDict
        } else {
            // If it's neither a string, array, nor dictionary, return the value as is
            return value
        }
    }

    // Decode any nested JSON strings recursively in the input dictionary
    let decodedJsonObject = decodeNestedJson(value)

    // Step 3: Convert the cleaned dictionary back to a JSON string
    guard let cleanedJsonData = try? JSONSerialization.data(withJSONObject: decodedJsonObject, options: []),
          let cleanedJsonString = String(data: cleanedJsonData, encoding: .utf8) else {
        Logging.error("Failed to serialize cleaned JSON dictionary")
        return nil
    }

    return cleanedJsonString
}
