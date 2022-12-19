//
//  ConnectView.swift
//  metamask-ios-sdk_Example
//
//  Created by Mpendulo Ndlovu on 2022/11/24.
//

import SwiftUI
import metamask_ios_sdk

extension Notification.Name {
    static let Event = Notification.Name("event")
    static let Channel = Notification.Name("channel")
    static let Connection = Notification.Name("connection")
}

struct ConnectView: View {
    @ObservedObject var ethereum = Ethereum.shared
    private let dappMetaData = DappMetadata(name: "myapp", url: "myapp.com")
    
    @State private var connected: Bool = false
    @State private var status: String = "Offline"
    
    @State private var channel: String?
    @State private var showProgressView = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Group {
                        HStack {
                            Text("Status")
                                .bold()
                            Spacer()
                            Text(status)
                                .font(.caption)
                        }
                        
                        if let channel = channel {
                            HStack {
                                Text("Channel")
                                    .bold()
                                Spacer()
                                Text(channel)
                                    .font(.caption)
                            }
                        }
                        
                        HStack {
                            Text("Chain ID")
                                .bold()
                            Spacer()
                            Text(ethereum.chainId ?? "-")
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Selected Address")
                                .bold()
                            Spacer()
                            Text(ethereum.selectedAddress)
                                .font(.caption)
                        }
                    }
                }
                
                if !ethereum.selectedAddress.isEmpty {
                    Section {
                        Group {
                            NavigationLink("Sign Transaction") {
                                SignView()
                            }
                            
                            NavigationLink("Send Transaction") {
                                TransactionView()
                            }
                        }
                    }
                }
                
                if ethereum.selectedAddress.isEmpty {
                    Section(footer: Text("This will open the MetaMask app. Please sign in and accept the connection prompt.")) {
                        ZStack {
                            Button {
                                showProgressView = true
                                ethereum.connect(dappMetaData)
                            } label: {
                                Text("Connect to MetaMask")
                                    .frame(maxWidth: .infinity, maxHeight: 32)
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .background(Color.blue.grayscale(0.5))
                            .modifier(ButtonCurvature())
                            
                            if showProgressView && !ethereum.connected {
                                ProgressView()
                                    .scaleEffect(2.0, anchor: .center)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            }
                        }
                    }
                }
            }
            .font(.body)
            .onReceive(NotificationCenter.default.publisher(for: .Connection)) { notification in
                status = notification.userInfo?["value"] as? String ?? "Offline"
            }
            .onReceive(NotificationCenter.default.publisher(for: .Channel)) { notification in
                channel = notification.userInfo?["value"] as? String
            }
            .navigationTitle("Dub Dapp")
            .onAppear {
                Ethereum.shared.response = ""
            }
        }
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView()
    }
}
