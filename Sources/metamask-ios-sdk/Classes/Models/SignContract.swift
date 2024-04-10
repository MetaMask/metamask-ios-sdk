//
//  SignContract.swift
//  metamask-ios-sdk
//

import Foundation

public struct SignContract: Mappable {
    let id: String
    let method: String
    let params: [SignContractParameter]
}

public struct SignContractParameter: Mappable {
    let domain: Domain
    let message: SignMessage
    let primaryType: String
    let types: ParameterTypes
}

public struct Domain: Mappable {
    let chainId: String
    let name: String
    let verifyingContract: String
    let version: String
}

public struct SignMessage: Mappable {
    let contents: String
    let from: Person
    let to: Person
}

public struct Person: Mappable {
    let name: String
    let wallet: String
}

public struct ParameterTypes: Mappable {
    let EIP712Domain: [ParameterType]
    let Mail: [ParameterType]
    let Person: [ParameterType]
}

public struct ParameterType: Mappable {
    let name: String
    let type: String
}
