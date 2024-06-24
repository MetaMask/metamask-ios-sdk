//
//  MockEthereumDelegate.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk

class MockEthereumDelegate: EthereumEventsDelegate {
    var chainIdChangedCalled = false
    var accountChangedCalled = false

    func chainIdChanged(_ chainId: String) {
        chainIdChangedCalled = true
    }

    func accountChanged(_ account: String) {
        accountChangedCalled = true
    }
}

