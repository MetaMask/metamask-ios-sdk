//
//  Typealiases.swift
//

import SocketIO
import Foundation

public typealias NetworkData = SocketData
public typealias RequestTask = Task<Any, Never>
public typealias CodableData = Codable & SocketData


