//
//  ConnectView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import metamask_ios_sdk

extension Notification.Name {
    static let Event = Notification.Name("event")
    static let Connection = Notification.Name("connection")
}

@MainActor
struct ConnectView: View {
    @ObservedObject var metaMaskSDK = MetaMaskSDK.shared(appMetadata)

    private static let appMetadata = AppMetadata(name: "Dub Dapp", url: "https://dubdapp.com")

    @State private var connected: Bool = false
    @State private var status: String = "Offline"

    @State private var errorMessage = ""
    @State private var showError = false
    
    @State private var connectAndSignResult = ""
    @State private var isConnect = true
    @State private var isConnectAndSign = false
    @State private var isConnectWith = false

    @State private var showProgressView = false

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
                            Text(metaMaskSDK.chainId)
                                .modifier(TextCaption())
                        }

                        HStack {
                            Text("Account")
                                .bold()
                                .modifier(TextCallout())
                            Spacer()
                            Text(metaMaskSDK.account)
                                .modifier(TextCaption())
                        }
                    }
                }

                if !metaMaskSDK.account.isEmpty {
                    Section {
                        Group {
                            NavigationLink("Sign") {
                                SignView().environmentObject(metaMaskSDK)
                            }
                            
                            NavigationLink("Chained signing") {
                                SignView(isChainedSigning: true).environmentObject(metaMaskSDK)
                            }

                            NavigationLink("Transact") {
                                TransactionView().environmentObject(metaMaskSDK)
                            }

                            NavigationLink("Switch chain") {
                                SwitchChainView().environmentObject(metaMaskSDK)
                            }
                        }
                    }
                }

                if metaMaskSDK.account.isEmpty {
                    Section {
                        Button {
                            isConnectWith = true
                        } label: {
                            Text("Connect With Request")
                                .modifier(TextButton())
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                        .sheet(isPresented: $isConnectWith, onDismiss: {
                            isConnectWith = false
                        }) {
                            TransactionView(isConnectWith: true)
                                .environmentObject(metaMaskSDK)
                        }
                        .modifier(ButtonStyle())
                        
                        Button {
                            isConnectAndSign = true
                        } label: {
                            Text("Connect & Sign")
                                .modifier(TextButton())
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                        .sheet(isPresented: $isConnectAndSign, onDismiss: {
                            isConnectAndSign = false
                        }) {
                            SignView(isConnectAndSign: true)
                                .environmentObject(metaMaskSDK)
                        }
                        .modifier(ButtonStyle())
                        
                        ZStack {
                            Button {
                                Task {
                                    await connectSDK()
                                }
                            } label: {
                                Text("Connect to MetaMask")
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
                    } footer: {
                        Text(connectAndSignResult)
                            .modifier(TextCaption())
                    }
                }
                
                if !metaMaskSDK.account.isEmpty {
                    Section {
                        Button {
                            metaMaskSDK.clearSession()
                        } label: {
                            Text("Clear Session")
                                .modifier(TextButton())
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                        .modifier(ButtonStyle())
                        
                        Button {
                            metaMaskSDK.disconnect()
                        } label: {
                            Text("Disconnect")
                                .modifier(TextButton())
                                .frame(maxWidth: .infinity, maxHeight: 32)
                        }
                        .modifier(ButtonStyle())
                    }
                }
            }
            .font(.body)
            .onReceive(NotificationCenter.default.publisher(for: .Connection)) { notification in
                status = notification.userInfo?["value"] as? String ?? "Offline"
            }
            .navigationTitle("Dub Dapp")
            .onAppear {
                showProgressView = false
            }
        }
    }
    
    func connectSDK() async {
        showProgressView = true
        let result = await metaMaskSDK.connect()
        showProgressView = false
        
        switch result {
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        default:
            break
        }
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView()
    }
}
