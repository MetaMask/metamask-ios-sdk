//
//  MockCommClient.swift
//  metamask-ios-sdk_Tests
//

import metamask_ios_sdk

class MockCommClient: CommClient {
    var connectCalled = false
    var disConnectCalled = false
    
    var appMetadata: AppMetadata?
    
    var sessionDuration: TimeInterval = 3600
    
    var trackEvent: ((Event, [String : Any]) -> Void)?
    
    var handleResponse: (([String : Any]) -> Void)?
    
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
        
    }
    
    func sendMessage(_ message: String, encrypt: Bool, options: [String : String]) {
        
    }
}
