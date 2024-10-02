//
//  MockClient.swift
//  metamask-ios-sdk_Tests
//

import metamask_ios_sdk
import XCTest

class MockCommClient: CommClient {
    var channelId: String = "randomId"
    
    var connectCalled = false
    var sendMessageCalled = false
    var disConnectCalled = false
    var addRequestCalled = false
    var requestAuthorisationCalled = false
    
    var addRequestJob: (() -> Void)?
    
    var expectation: XCTestExpectation?
    
    var appMetadata: AppMetadata?
    
    var sessionDuration: TimeInterval = 3600
    
    var trackEvent: ((Event, [String : Any]) -> Void)?
    
    var handleResponse: (([String : Any]) -> Void)?
    
    var onClientsTerminated: (() -> Void)?
    
    func requestAuthorisation() {
        requestAuthorisationCalled = true
    }
    
    func connect(with request: String?) {
        connectCalled = true
    }
    
    func disconnect() {
        disConnectCalled = true
    }
    
    func clearSession() {
        disConnectCalled = true
    }
    
    func addRequest(_ job: @escaping RequestJob) {
        addRequestCalled = true
        addRequestJob = job
    }
    
    func sendMessage<T: Codable>(_ message: T, encrypt: Bool, options: [String : String]) {
        sendMessageCalled = true
        expectation?.fulfill()
    }
}
