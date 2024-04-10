//
//  CommLayer.swift
//  metamask-ios-sdk
//

import Foundation

public enum Transport {
    case socket
    case deeplinking(dappScheme: String)
}
