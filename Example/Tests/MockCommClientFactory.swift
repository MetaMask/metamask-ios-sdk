//
//  MockCommClientFactory.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk

class MockCommClientFactory: CommClientFactory {
    override func socketClient() -> CommClient {
        MockSocketCommClient()
    }
    
    override func deeplinkClient(dappScheme: String) -> CommClient {
        MockDeeplinkCommClient()
    }
}
