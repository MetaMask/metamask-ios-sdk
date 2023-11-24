//
//  RPCRequest.swift
//  metamask-ios-sdk
//

import Foundation
import SocketIO

public protocol RPCRequest: CodableData {
    var id: String { get }
    var method: String { get }
    associatedtype ParameterType: CodableData
    var params: ParameterType { get }
    var methodType: EthereumMethod { get }
}
