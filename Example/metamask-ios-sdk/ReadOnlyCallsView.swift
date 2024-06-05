import Foundation

//
//  ReadOnlyCallsView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import Combine
import metamask_ios_sdk

@MainActor
struct ReadOnlyCallsView: View {
    @EnvironmentObject var metamaskSDK: MetaMaskSDK

    @State private var showProgressView = false

    @State var balanceResult: String = ""
    @State var gasPriceResult: String = ""
    @State var web3ClientVersionResult: String = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 16) {
                    Spacer()

                    VStack {
                        Button {
                            Task {
                                await getBalance()
                            }
                        } label: {
                            Text("Get Balance")
                                .modifier(TextButton())
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                        .modifier(ButtonStyle())

                        Text(balanceResult)
                            .modifier(TextCaption())
                    }

                    VStack {
                        Button {
                            Task {
                                await getGasPrice()
                            }
                        } label: {
                            Text("Get Gas Price")
                                .modifier(TextButton())
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                        .modifier(ButtonStyle())

                        Text(gasPriceResult)
                            .modifier(TextCaption())
                    }

                    VStack {
                        Button {
                            Task {
                                await getWeb3ClientVersion()
                            }
                        } label: {
                            Text("Get Web3 Client Version")
                                .modifier(TextButton())
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                        .modifier(ButtonStyle())

                        Text(web3ClientVersionResult)
                            .modifier(TextCaption())
                    }
                }
                .padding(.horizontal)

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
            .onAppear {
                showProgressView = false
            }
        }
        .navigationTitle("Read-Only Calls")
    }

    func getBalance() async {
        let from = metamaskSDK.account
        let params: [String] = [from, "latest"]
        let getBalanceRequest = EthereumRequest(
            method: .ethGetBalance,
            params: params
        )

        showProgressView = true
        let requestResult = await metamaskSDK.request(getBalanceRequest)
        showProgressView = false

        switch requestResult {
        case let .success(value):
            balanceResult = value
            errorMessage = ""
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func getGasPrice() async {
        let params: [String] = []
        let getGasPriceRequest = EthereumRequest(
            method: .ethGasPrice,
            params: params
        )

        showProgressView = true
        let requestResult = await metamaskSDK.request(getGasPriceRequest)
        showProgressView = false

        switch requestResult {
        case let .success(value):
            gasPriceResult = value
            errorMessage = ""
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func getWeb3ClientVersion() async {
        let params: [String] = []
        let getWeb3ClientVersionRequest = EthereumRequest(
            method: .web3ClientVersion,
            params: params
        )

        showProgressView = true
        let requestResult = await metamaskSDK.request(getWeb3ClientVersionRequest)
        showProgressView = false

        switch requestResult {
        case let .success(value):
            web3ClientVersionResult = value
            errorMessage = ""
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct ReadOnlyCalls_Previews: PreviewProvider {
    static var previews: some View {
        ReadOnlyCallsView()
    }
}
