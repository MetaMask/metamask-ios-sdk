//
//  ConnectView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import Combine
import metamask_ios_sdk

extension Notification.Name {
    static let Event = Notification.Name("event")
    static let Connection = Notification.Name("connection")
}

struct ConnectView: View {
    @ObservedObject var ethereum = MetaMaskSDK.shared.ethereum
    @State private var cancellables: Set<AnyCancellable> = []

    private let dapp = Dapp(name: "Dub Dapp", url: "https://dubdapp.com")

    @State private var connected: Bool = false
    @State private var status: String = "Offline"

    @State private var errorMessage = ""
    @State private var showError = false

    @State private var showProgressView = false
    @State private var showToast = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Group {
                        HStack {
                            Text("Status")
                                .bold()
                                .modifier(TextCallout())
                            Spacer()
                            Text(status)
                                .modifier(TextCaption())
                        }

                        HStack {
                            Text("Chain ID")
                                .bold()
                                .modifier(TextCallout())
                            Spacer()
                            Text(ethereum.chainId)
                                .modifier(TextCaption())
                        }

                        HStack {
                            Text("Account")
                                .bold()
                                .modifier(TextCallout())
                            Spacer()
                            Text(ethereum.selectedAddress)
                                .modifier(TextCaption())
                        }
                    }
                }

                if !ethereum.selectedAddress.isEmpty {
                    Section {
                        Group {
                            NavigationLink("Sign") {
                                SignView()
                            }

                            NavigationLink("Transact") {
                                TransactionView()
                            }

                            NavigationLink("Switch chain") {
                                SwitchChainView()
                            }
                            
                            Button {
                                ethereum.clearSession()
                                showToast = true
                            } label: {
                                Text("Clear Session")
                                    .modifier(TextButton())
                                    .frame(maxWidth: .infinity, maxHeight: 32)
                            }
                            .toast(isPresented: $showToast) {
                                ToastView(message: "Session cleared")
                            }
                            .modifier(ButtonStyle())
                        }
                    }
                }

                if ethereum.selectedAddress.isEmpty {
                    Section {
                        ZStack {
                            Button {
                                showProgressView = true

                                ethereum.connect(dapp)?.sink(receiveCompletion: { completion in
                                    switch completion {
                                    case let .failure(error):
                                        showProgressView = false
                                        errorMessage = error.localizedDescription
                                        showError = true
                                        print("Connection error: \(errorMessage)")
                                    default: break
                                    }
                                }, receiveValue: { result in
                                    showProgressView = false
                                    print("Connection result: \(result)")
                                }).store(in: &cancellables)
                            } label: {
                                Text("Connect to MetaMask")
                                    .modifier(TextButton())
                                    .frame(maxWidth: .infinity, maxHeight: 32)
                            }
                            .modifier(ButtonStyle())

                            if showProgressView && !ethereum.connected {
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
                    } footer: {
                        Text("This will open the MetaMask app. Please sign in and accept the connection prompt.")
                            .modifier(TextCaption())
                    }
                }
            }
            .font(.body)
            .onReceive(NotificationCenter.default.publisher(for: .Connection)) { notification in
                status = notification.userInfo?["value"] as? String ?? "Offline"
            }
            .navigationTitle("Dub Dapp")
        }
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView()
    }
}
