//
//  ConnectView.swift
//  metamask-ios-sdk_Example
//
//  Created by Mpendulo Ndlovu on 2022/11/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI

import SwiftUI

extension Notification.Name {
    static let Event = Notification.Name("event")
    static let Channel = Notification.Name("channel")
    static let Deeplink = Notification.Name("deeplink")
    static let Connection = Notification.Name("connection")
}

struct ConnectView: View {
    @State var title: String = "Connect"
    @State var status: String = "Offline"
    @State var connected: Bool = false
    @State var url: String?
    @State var channel: String?
    @State var event: String?
    
    var onConnect: (() -> Void)?
    var onDeeplink: (() -> Void)?
    
    init(onConnect: (() -> Void)?,
         onDeeplink: (() -> Void)?) {
        self.onConnect = onConnect
        self.onDeeplink = onDeeplink
    }
    
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
                
                Spacer()
                
                if connected {
                    Button("Open MetaMask") {
                        onDeeplink?()
                    }
                } else {
                    Button("Connect SDK") {
                        onConnect?()
                    }
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
            .onReceive(NotificationCenter.default.publisher(for: .Deeplink)) { notification in
                url = notification.userInfo?["value"] as? String
                connected = true
            }
            .navigationTitle("MetaMask iOS SDK")
        }
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView(onConnect: nil, onDeeplink: nil)
    }
}
