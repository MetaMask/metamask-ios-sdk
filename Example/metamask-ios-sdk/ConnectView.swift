//
//  ConnectView.swift
//  metamask-ios-sdk_Example
//
//  Created by Mpendulo Ndlovu on 2022/11/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
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
    @State private var title: String = "Connect"
    @State private var status: String = "Offline"
    
    @State private var url: String?
    @State private var event: String?
    @State private var channel: String?
    @State private var showProgressView = false
    
    var onConnect: (() -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack {
                    Text("Status")
                        .bold()
                    Text(status)
                        .font(.caption)
                }
                
                if let channel = channel {
                    VStack {
                        Text("Channel")
                            .bold()
                        Text(channel)
                            .font(.caption)
                    }
                }
                
                VStack {
                    Text("Chain ID")
                        .bold()
                    Text(ethereum.chainId ?? "-")
                        .font(.caption)
                }
                
                VStack {
                    Text("Selected Address")
                        .bold()
                    Text(ethereum.selectedAddress ?? "-")
                        .font(.caption)
                }
                
                if let url = url {
                    Text("URL")
                        .bold()
                    Text(url)
                        .font(.caption)
                }
                
                if let event = event {
                    VStack {
                        Text("Event")
                            .bold()
                        Text(event)
                            .font(.caption)
                    }
                }
                
                if showProgressView && ethereum.chainId == nil {
                    ProgressView()
                }
                
                Spacer()
                
                Button("Connect to MetaMask") {
                    showProgressView = true
                    ethereum.connect(dappMetaData)
                }
            }
            .font(.body)
            .padding()
            .onReceive(NotificationCenter.default.publisher(for: .Connection)) { notification in
                status = notification.userInfo?["value"] as? String ?? "Offline"
            }
            .onReceive(NotificationCenter.default.publisher(for: .Channel)) { notification in
                channel = notification.userInfo?["value"] as? String
            }
            .onReceive(NotificationCenter.default.publisher(for: .Event)) { notification in
                event = notification.userInfo?["value"] as? String
            }
            .navigationTitle("Example Dapp")
        }
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView(onConnect: nil)
    }
}
