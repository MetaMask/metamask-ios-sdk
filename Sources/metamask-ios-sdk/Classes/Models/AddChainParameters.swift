//
//  AddChainParameters.swift
//  metamask-ios-sdk
//


import Foundation

public struct AddChainParameters: CodableData {
    public let chainId: String
    public let chainName: String
    public let rpcUrls: [String]
    public let iconUrls: [String]?
    public let blockExplorerUrls: [String]?
    public let nativeCurrency: NativeCurrency

    public func socketRepresentation() -> NetworkData {
        [
            "chainId": chainId,
            "chainName": chainName,
            "rpcUrls": rpcUrls,
            "iconUrls": iconUrls ?? [],
            "blockExplorerUrls": blockExplorerUrls ?? [],
            "nativeCurrency": nativeCurrency.socketRepresentation()
        ]
    }
}
