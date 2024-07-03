//
//  MockEthereumDelegate.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk

class MockEthereumDelegate: EthereumEventsDelegate {
    var chainIdChangedCalled = false
    var accountChangedCalled = false
    
    var chainId: String?
    var account: String?

    func chainIdChanged(_ chainId: String) {
        self.chainId = chainId
        chainIdChangedCalled = true
    }

    func accountChanged(_ account: String) {
        self.account = account
        accountChangedCalled = true
    }
}

