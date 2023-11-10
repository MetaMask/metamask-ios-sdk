//
//  NetworkView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import metamask_ios_sdk

@MainActor
struct NetworkView: View {
    @EnvironmentObject var metamaskSDK: MetaMaskSDK
    @Environment(\.presentationMode) var presentationMode
    @State var networkUrl: String = ""

    var body: some View {
        Form {
            Section {
                Text("Current network URL")
                    .modifier(TextCallout())
                TextField("Network url", text: $metamaskSDK.networkUrl)
                    .modifier(TextCaption())
                    .frame(minHeight: 32)
                    .modifier(TextCurvature())
                    .disabled(true)
            }

            Section {
                Text("New network URL")
                    .modifier(TextCallout())
                TextField("Network url", text: $networkUrl)
                    .modifier(TextCaption())
                    .frame(minHeight: 32)
                    .modifier(TextCurvature())
                    .autocapitalization(.none)
            }

            Section {
                Button {
                    changeNetwork()
                } label: {
                    Text("Update")
                        .modifier(TextButton())
                        .frame(maxWidth: .infinity, maxHeight: 32)
                }
                .font(.title3)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color.blue.grayscale(0.5))
                .modifier(ButtonCurvature())
            } footer: {
                Text("You can replace with your local IP address etc")
                    .modifier(TextCaption())
            }
        }
    }

    func changeNetwork() {
        metamaskSDK.networkUrl = networkUrl
        presentationMode.wrappedValue.dismiss()
    }
}

struct NetworkView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkView()
    }
}
