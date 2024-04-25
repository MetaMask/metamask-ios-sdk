//
//  DeeplinkManagerTests.swift
//  metamask-ios-sdk
//

import XCTest
import metamask_ios_sdk

class DeeplinkManagerTests: XCTestCase {
    var deeplinkManager: DeeplinkManager!
    
    override func setUp() {
        super.setUp()
        deeplinkManager = DeeplinkManager()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testOnReceiveMessageIsCalledWhenHandlingMessage() {
        let message = "Message to send".base64Encode() ?? ""
        let urlString = "metamask://mmsdk?message=\(message)"
        let url = URL(string: urlString)!
        var messageReceived = false
        
        deeplinkManager.onReceiveMessage = { _ in
            messageReceived = true
        }
        
        deeplinkManager.handleUrl(url)
        XCTAssert(messageReceived)
    }
    
    func testConnectDeeplinkHasCorrectChannelId() {
        let channelId = "2468"
        let url = "target://connect?scheme=testdapp&channelId=\(channelId)"
        let deeplink = deeplinkManager.getDeeplink(url)
        XCTAssert(deeplink == Deeplink.connect(pubkey: nil, channelId: channelId, request: nil))
    }
    
    func testConnectDeeplinkHasCorrectPublicKey() {
        let pubkey = "asdfghjkl"
        let channelId = "2468"
        let url = "target://connect?scheme=testdapp&pubkey=\(pubkey)&channelId=\(channelId)"
        let deeplink = deeplinkManager.getDeeplink(url)
        XCTAssert(deeplink == Deeplink.connect(pubkey: pubkey, channelId: channelId, request: nil))
    }
    
    func testMessageDeeplinkHasCorrectMessageAndPubkey() {
        let pubkey = "asdfghjkl"
        let channelId = "2468"
        let message = "base64EncodedRequest"
        let url = "target://mmsdk?scheme=testdapp&message=\(message)&pubkey=\(pubkey)&channelId=\(channelId)"
        let deeplink = deeplinkManager.getDeeplink(url)
        XCTAssert(deeplink == Deeplink.mmsdk(message: message, pubkey: pubkey, channelId: nil))
    }
    
    func testDeeplinkMissingSchemeIsInvalid() {
        let channelId = "2468"
        let request = "base64EncodedRequest"
        let url = "connect?channelId=\(channelId)&request=\(request)"
        let deeplink = deeplinkManager.getDeeplink(url)
        XCTAssertNil(deeplink)
    }
    
    func testDeeplinkMissingHostIsInvalid() {
        let channelId = "2468"
        let request = "base64EncodedRequest"
        let url = "target://?channelId=\(channelId)&request=\(request)"
        let deeplink = deeplinkManager.getDeeplink(url)
        XCTAssertNil(deeplink)
    }
}
