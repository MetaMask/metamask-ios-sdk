//
//  ConnectView.swift
//  metamask-ios-sdk_Example
//
//  Created by Mpendulo Ndlovu on 2022/11/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI

import SwiftUI

struct ConnectView: View {
    @State var title: String = "Connect"
    @State var status: String = "Offline"
    @State var url: String = "www.google.com"
    
    var body: some View {
        VStack {
            Link(title, destination: URL(string: url)!)
            HStack {
                Text("Status:")
                Text(status)
            }
        }
        .padding()
        .onAppear {
            NotificationCenter.default.publisher(for: Notification.Name(rawValue: "onConnect"))
                .sink { notification in
                    print(notification)
                    status = "Connected"
            }
            NotificationCenter.default.publisher(for: Notification.Name(rawValue: "joinChannel"))
                .sink { notification in
                    print(notification)
                    status = "Joined channel"
            }
            NotificationCenter.default.publisher(for: Notification.Name(rawValue: "Deeplink"))
                .sink { notification in
                    print(notification)
                    status = "Waiting for other participant"
            }
        }
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView()
    }
}
