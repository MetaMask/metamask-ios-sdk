//
//  CommunicationClient.swift
//  metamask-ios-sdk
//

import Foundation

public typealias RequestJob = () -> Void

public protocol CommunicationClient: AnyObject {
    var communicationLayer: CommunicationLayer { get set }
    var appMetadata: AppMetadata? { get set }
    var useDeeplinks: Bool { get set }
    var isConnected: Bool { get }
    var networkUrl: String { get set }
    var sessionDuration: TimeInterval { get set }

    var tearDownConnection: (() -> Void)? { get set }
    var onClientsTerminated: (() -> Void)? { get set }
    var receiveEvent: (([String: Any]) -> Void)? { get set }
    var receiveResponse: ((String, [String: Any]) -> Void)? { get set }

    func connect()
    func disconnect()
    func clearSession()
    func track(event: Event)
    func requestAuthorisation()
    func addRequest(_ job: @escaping RequestJob)
    func sendMessage<T: CodableData>(_ message: T, encrypt: Bool)
}
