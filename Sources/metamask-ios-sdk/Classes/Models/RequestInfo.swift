//
//  RequestInfo.swift
//  metamask-ios-sdk
//

import Foundation

public struct RequestInfo: CodableData, Mappable {
    public let type: String
    public let originator: OriginatorInfo
    public let originatorInfo: OriginatorInfo

    public func socketRepresentation() -> NetworkData {
        ["type": type,
         "originator": originator.socketRepresentation(), // Backward compatibility with MetaMask mobile
         "originatorInfo": originatorInfo.socketRepresentation()]
    }
}
