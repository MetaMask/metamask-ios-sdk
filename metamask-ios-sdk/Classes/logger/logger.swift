//
//  MetaMaskSDK.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import OSLog
import Foundation

class Logging {
    static func log(_ message: String) {
        Logger().log("\(message)")
    }
    
    static func error(_ error: String) {
        Logger().log(level: .error, "\(error)")
    }
    
    static func error(_ error: Error) {
        Logger().log(level: .error, "\(error.localizedDescription)")
    }
}
