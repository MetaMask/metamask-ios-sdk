//
//  CommLayer.swift
//  metamask-ios-sdk
//

import Foundation

public enum CommLayer {
    case socket
    case deeplinking(dappScheme: String)
}
