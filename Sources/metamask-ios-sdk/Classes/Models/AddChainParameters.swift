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
    
    public init(chainId: String, chainName: String, rpcUrls: [String], iconUrls: [String]?, blockExplorerUrls: [String]?, nativeCurrency: NativeCurrency) {
        self.chainId = chainId
        self.chainName = chainName
        self.rpcUrls = rpcUrls
        self.iconUrls = iconUrls
        self.blockExplorerUrls = blockExplorerUrls
        self.nativeCurrency = nativeCurrency
    }

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
