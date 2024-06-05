//
//  Mappable.swift
//  metamask-ios-sdk
//

import Foundation

public protocol Mappable: Codable { }

public extension Mappable {
    func toDictionary() -> [String: Any]? {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(self)
            guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                Logging.error("Mappable:: Error converting JSON data to dictionary")
                return nil
            }
            return jsonObject
        } catch {
            print("Error encoding JSON: \(error)")
            Logging.error("Mappable:: Error encoding JSON: \(error)")
            return nil
        }
    }

    func toJsonString() -> String? {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            Logging.error("Error encoding JSON: \(error)")
            return nil
        }
    }
}

extension String: Mappable {}
extension Dictionary: Mappable where Key == String, Value: Codable {}
