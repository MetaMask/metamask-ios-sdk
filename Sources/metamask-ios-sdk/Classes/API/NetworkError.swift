//
//  NetworkError.swift
//

import Foundation

enum NetworkError: Error {
    case invalidUrl
    case invalidData
    
    var message: String {
        switch self {
        case .invalidUrl:
            return "Invalid url"
        case .invalidData:
            return "Invalid data"
        }
    }
}
