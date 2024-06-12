//
//  MockDeeplinkManager.swift
//  metamask-ios-sdk_Tests
//

@testable import metamask_ios_sdk

class MockDeeplinkManager: DeeplinkManager {
    var handleUrlCalled = false

    override func handleUrl(_ url: URL) {
        handleUrlCalled = true
    }
}


