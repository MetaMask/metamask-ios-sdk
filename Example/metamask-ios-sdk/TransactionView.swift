//
//  TransactionView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import Combine
import metamask_ios_sdk

@MainActor
struct TransactionView: View {
    @EnvironmentObject var metamaskSDK: MetaMaskSDK

    @State private var amount = "0x000000000000000001"
    @State var result: String = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var to = "0x0000000000000000000000000000000000000000"
    @State var isConnectWith: Bool = false
    @State private var sendTransactionTitle = "Send Transaction"
    @State private var connectWithSendTransactionTitle = "Connect & Send Transaction"

    @State private var showProgressView = false

    var body: some View {
        Form {
            Section {
                Text("From")
                    .modifier(TextCallout())
                TextField("Enter sender address", text: $metamaskSDK.account)
                    .modifier(TextCaption())
                    .frame(minHeight: 32)
                    .modifier(TextCurvature())
            }

            Section {
                Text("To")
                    .modifier(TextCallout())
                TextEditor(text: $to)
                    .modifier(TextCaption())
                    .frame(minHeight: 32)
                    .modifier(TextCurvature())
            }

            Section {
                Text("Amount")
                    .modifier(TextCallout())
                TextField("Amount", text: $amount)
                    .modifier(TextCaption())
                    .frame(minHeight: 32)
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
                            await sendTransaction()
                        }
                    } label: {
                        Text(isConnectWith ? connectWithSendTransactionTitle : sendTransactionTitle)
                            .modifier(TextButton())
                            .frame(maxWidth: .infinity, maxHeight: 32)
                    }
                    .alert(isPresented: $showError) {
                        Alert(
                            title: Text("Error"),
                            message: Text(errorMessage)
                        )
                    }
                    .modifier(ButtonStyle())

                    if showProgressView {
                        ProgressView()
                            .scaleEffect(1.5, anchor: .center)
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    }
                }
            }
        }
        .background(Color.blue.grayscale(0.5))
    }

    func sendTransaction() async {
        let transaction = Transaction(
            to: to,
            from: metamaskSDK.account,
            value: amount
        )

        let parameters: [Transaction] = [transaction]

        let transactionRequest = EthereumRequest(
            method: .ethSendTransaction,
            params: parameters // eth_sendTransaction rpc call expects an array parameters object
        )

        showProgressView = true

        let transactionResult = isConnectWith
        ? await metamaskSDK.connectWith(transactionRequest)
        : await metamaskSDK.sendTransaction(from: metamaskSDK.account, to: to, amount: amount)

        showProgressView = false

        switch transactionResult {
        case let .success(value):
            result = value
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct Transaction: CodableData {
    let to: String
    let from: String
    let value: String
    let data: String?

    init(to: String, from: String, value: String, data: String? = nil) {
        self.to = to
        self.from = from
        self.value = value
        self.data = data
    }

    func socketRepresentation() -> NetworkData {
        [
            "to": to,
            "from": from,
            "value": value,
            "data": data
        ]
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
    }
}
