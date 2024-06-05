//
//  SignView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import Combine
import metamask_ios_sdk

@MainActor
struct SignView: View {
    @EnvironmentObject var metamaskSDK: MetaMaskSDK

    @State var signMessage = ""
    @State private var showProgressView = false

    @State var result: String = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State var isConnectAndSign = false
    @State var isChainedSigning = false

    private let signButtonTitle = "Sign"
    private let connectAndSignButtonTitle = "Connect & Sign"

    var body: some View {
        GeometryReader { geometry in
            Form {
                Section {
                    Text("Message")
                        .modifier(TextCallout())
                    TextEditor(text: $signMessage)
                        .modifier(TextCaption())
                        .frame(height: geometry.size.height / 2)
                        .modifier(TextCurvature())
                }

                Section {
                    Text("Result")
                        .modifier(TextCallout())
                    TextEditor(text: $result)
                        .modifier(TextCaption())
                        .frame(minHeight: 40)
                        .modifier(TextCurvature())
                }

                Section {
                    ZStack {
                        Button {
                            Task {
                                await
                                if isConnectAndSign { connectAndSign() } else if isChainedSigning { signChainedMessages() } else { signMessage() }
                            }
                        } label: {
                            Text(isConnectAndSign ? connectAndSignButtonTitle : signButtonTitle)
                                .modifier(TextButton())
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                        .modifier(ButtonStyle())

                        if showProgressView {
                            ProgressView()
                                .scaleEffect(1.5, anchor: .center)
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        }
                    }
                    .alert(isPresented: $showError) {
                        Alert(
                            title: Text("Error"),
                            message: Text(errorMessage)
                        )
                    }
                }
            }
        }
        .onAppear {
            updateMessage()
            showProgressView = false
        }
        .onChange(of: metamaskSDK.chainId) { _ in
            updateMessage()
        }
    }

    func updateMessage() {
        if isChainedSigning {
            let chainedSigningMessages: [String] = [
                ChainedSigningMessage.helloWorld,
                ChainedSigningMessage.transactionData,
                ChainedSigningMessage.byeWorld
            ]
            signMessage = chainedSigningMessages.joined(separator: "\n======================\n")
        } else if isConnectAndSign {
            signMessage = "{\"domain\":{\"name\":\"Ether Mail\",\"verifyingContract\":\"0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC\",\"version\":\"1\"},\"message\":{\"contents\":\"Hello, Linda!\",\"from\":{\"name\":\"Aliko\",\"wallets\":[\"0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826\",\"0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF\"]},\"to\":[{\"name\":\"Linda\",\"wallets\":[\"0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB\",\"0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57\",\"0xB0B0b0b0b0b0B000000000000000000000000000\"]}]},\"primaryType\":\"Mail\",\"types\":{\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}],\"Group\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"members\",\"type\":\"Person[]\"}],\"Mail\":[{\"name\":\"from\",\"type\":\"Person\"},{\"name\":\"to\",\"type\":\"Person[]\"},{\"name\":\"contents\",\"type\":\"string\"}],\"Person\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"wallets\",\"type\":\"address[]\"}]}}"
        } else {
            let jsonData = "{\"types\": {\"EIP712Domain\": [{ \"name\": \"name\", \"type\": \"string\" },{ \"name\": \"version\", \"type\": \"string\" },{ \"name\": \"chainId\", \"type\": \"uint256\" },{ \"name\": \"verifyingContract\", \"type\": \"address\" }],\"Person\": [{ \"name\": \"name\", \"type\": \"string\" },{ \"name\": \"wallet\", \"type\": \"address\" }],\"Mail\": [{ \"name\": \"from\", \"type\": \"Person\" },{ \"name\": \"to\", \"type\": \"Person\" },{ \"name\": \"contents\", \"type\": \"string\" }]},\"primaryType\": \"Mail\",\"domain\": {\"name\": \"Ether Mail\",\"version\": \"1\",\"chainId\": \"\(metamaskSDK.chainId)\",\"verifyingContract\": \"0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC\"},\"message\": {\"from\": { \"name\": \"Kinno\", \"wallet\": \"0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826\" },\"to\": { \"name\": \"Bob\", \"wallet\": \"0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB\" },\"contents\": \"Hello, Busa!\"}}".data(using: .utf8)!

            do {
                let decoder = JSONDecoder()
                let signParams = try decoder.decode(SignContractParameter.self, from: jsonData)
                signMessage = signParams.toJsonString() ?? ""
            } catch {
                Logging.error("SignView:: Decoding error: \(error.localizedDescription)")
                signMessage = ""
            }
        }
    }

    func signMessage() async {
        let account = metamaskSDK.account

        showProgressView = true
        let requestResult = await metamaskSDK.signTypedDataV4(typedData: signMessage, address: account)
        showProgressView = false

        switch requestResult {
        case let .success(value):
            result = value
            errorMessage = ""
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func signChainedMessages() async {
        let from = metamaskSDK.account
        let helloWorldParams: [String] = [ChainedSigningMessage.helloWorld, from]
        let transactionDataParams: [String] = [ChainedSigningMessage.transactionData, from]
        let byeWorldParams: [String] = [ChainedSigningMessage.byeWorld, from]

        let helloWorldSignRequest = EthereumRequest(
            method: .personalSign,
            params: helloWorldParams
        )

        let transactionDataSignRequest = EthereumRequest(
            method: .personalSign,
            params: transactionDataParams
        )

        let byeWorldSignRequest = EthereumRequest(
            method: .personalSign,
            params: byeWorldParams
        )

        let requestBatch: [EthereumRequest] = [helloWorldSignRequest, transactionDataSignRequest, byeWorldSignRequest]

        showProgressView = true
        let requestResult = await metamaskSDK.batchRequest(requestBatch)
        showProgressView = false

        switch requestResult {
        case let .success(value):
            result = value.joined(separator: "\n======================\n")
            errorMessage = ""
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func connectAndSign() async {
        showProgressView = true
        let connectSignResult = await metamaskSDK.connectAndSign(message: signMessage)
        showProgressView = false

        switch connectSignResult {
        case let .success(value):
            result = value
            errorMessage = ""
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct SignView_Previews: PreviewProvider {
    static var previews: some View {
        SignView()
    }
}

struct ChainedSigningMessage {
    static let helloWorld = "Hello, world, signing in!"
    static let transactionData = "{\"data\":\"0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675\",\"from\": \"0x0000000000000000000000000000000000000000\",\"gas\": \"0x76c0\",\"gasPrice\": \"0x9184e72a000\",\"to\": \"0xd46e8dd67c5d32be8058bb8eb970870f07244567\",\"value\": \"0x9184e72a\"}"
    static let byeWorld = "Last message to sign!"
}
