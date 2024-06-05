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

private let DAPP_SCHEME = "dubdapp"

@MainActor
struct ConnectView: View {
    @State var selectedTransport: Transport = .deeplinking(dappScheme: DAPP_SCHEME)
    @State private var dappScheme: String = DAPP_SCHEME

    private static let appMetadata = AppMetadata(
        name: "Dub Dapp",
        url: "https://dubdapp.com",
        iconUrl: "https://cdn.sstatic.net/Sites/stackoverflow/Img/apple-touch-icon.png"
    )

    // We recommend adding support for Infura API for read-only RPCs (direct calls) via SDKOptions
    @ObservedObject var metaMaskSDK = MetaMaskSDK.shared(
                    appMetadata,
                    transport: .deeplinking(dappScheme: DAPP_SCHEME),
                    sdkOptions: nil // SDKOptions(infuraAPIKey: "####")
                )

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

                if #available(iOS 17.0, *) {
                    Section {
                        Picker("Transport Layer", selection: $selectedTransport) {
                            Text("Socket").tag(Transport.socket)
                            Text("Deeplinking").tag(Transport.deeplinking(dappScheme: dappScheme))
                        }
                        .onChange(of: selectedTransport, initial: false, { _, newValue in
                            metaMaskSDK.updateTransportLayer(newValue)
                        })

                        if case .deeplinking = selectedTransport {
                            TextField("Dapp Scheme", text: $dappScheme)
                                .frame(minHeight: 32)
                                .modifier(TextCurvature())
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

                            NavigationLink("Read-only RPCs") {
                                ReadOnlyCallsView().environmentObject(metaMaskSDK)
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
        case .success:
            status = "Online"
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView()
    }
}
