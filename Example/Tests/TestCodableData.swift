//
//  TestCodableData.swift
//  metamask-ios-sdk_Tests
//

import Foundation
@testable import metamask_ios_sdk

struct TestCodableData: CodableData, Equatable {
    var id: String
    var message: String
}
