//
//  CommunicationChannel.swift
//  metamask-ios-sdk
//

public protocol CommunicationChannel {
    associatedtype ChannelData
    associatedtype EventType
    
    var isConnected: Bool { get }
    var networkUrl: String { get set }
    
    func connect()
    func disconnect()
    func tearDown()
    
    func emit(_ event: String, _ data: ChannelData)
    func on(_ event: String, completion: @escaping ([Any]) -> Void)
    func on(_ event: EventType, completion: @escaping ([Any]) -> Void)
}
