//
//  MockURLOpener.swift
//  metamask-ios-sdk_Tests
//

import Foundation
import metamask_ios_sdk

class MockURLOpener: URLOpener {
    var openedURL: URL?

    func open(_ url: URL) {
        openedURL = url
    }
}
