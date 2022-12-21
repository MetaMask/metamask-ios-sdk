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
    @ObservedObject var ethereum = Ethereum.shared
    @State private var cancellables: Set<AnyCancellable> = []
    
    private let dappMetaData = DappMetadata(name: "Dub Dapp", url: "dubdapp.com")
    
    @State private var connected: Bool = false
    @State private var status: String = "Offline"
    
    @State private var errorMessage = ""
    @State private var showError = false
    
    @State private var showProgressView = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Group {
                        HStack {
                            Text("Status")
                                .font(.callout)
                                .bold()
                            Spacer()
                            Text(status)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Chain ID")
                                .font(.callout)
                                .bold()
                            Spacer()
                            Text(ethereum.chainId ?? "")
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Account")
                                .font(.callout)
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
                                
                                ethereum.connect(dappMetaData)?.sink(receiveCompletion: { completion in
                                    switch completion {
                                    case .failure(let error):
                                        errorMessage = error.localizedDescription
                                        showError = true
                                        print("Connection error: \(errorMessage)")
                                    default: break
                                    }
                                }, receiveValue: { result in
                                    print("Connection result: \(result)")
                                }).store(in: &cancellables)
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
                        .alert(isPresented: $showError) {
                            Alert(
                                title: Text("Authorization Error"),
                                message: Text(errorMessage)
                            )
                        }
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
