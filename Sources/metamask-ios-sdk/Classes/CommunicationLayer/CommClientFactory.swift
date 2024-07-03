//
//  CommClientFactory.swift
//  metamask-ios-sdk
//

import Foundation

public class CommClientFactory {
    func socketClient() -> CommClient {
        Dependencies.shared.socketClient
    }

    func deeplinkClient(dappScheme: String) -> CommClient {
        Dependencies.shared.deeplinkClient(dappScheme: dappScheme)
    }
}
