//
//  SignView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import Combine
import metamask_ios_sdk

struct SignView: View {
    @ObservedObject var ethereum: Ethereum = MetaMaskSDK.shared.ethereum

    @State var message = "{\"domain\":{\"chainId\":1,\"name\":\"Ether Mail\",\"verifyingContract\":\"0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC\",\"version\":\"1\"},\"message\":{\"contents\":\"Hello, Linda!\",\"from\":{\"name\":\"Aliko\",\"wallets\":[\"0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826\",\"0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF\"]},\"to\":[{\"name\":\"Linda\",\"wallets\":[\"0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB\",\"0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57\",\"0xB0B0b0b0b0b0B000000000000000000000000000\"]}]},\"primaryType\":\"Mail\",\"types\":{\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}],\"Group\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"members\",\"type\":\"Person[]\"}],\"Mail\":[{\"name\":\"from\",\"type\":\"Person\"},{\"name\":\"to\",\"type\":\"Person[]\"},{\"name\":\"contents\",\"type\":\"string\"}],\"Person\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"wallets\",\"type\":\"address[]\"}]}}"

    @State private var cancellables: Set<AnyCancellable> = []

    @State var result: String = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        GeometryReader { geometry in
            Form {
                Section {
                    Text("Message")
                        .modifier(TextCallout())
                    TextEditor(text: $message)
                        .modifier(TextCaption())
                        .frame(height: geometry.size.height / 2)
                        .modifier(TextCurvature())
                }

                Section {
                    Text("Result")
                        .modifier(TextCallout())
                    TextEditor(text: $result)
                        .modifier(TextCaption())
                        .frame(minHeight: 40)
                        .modifier(TextCurvature())
                }

                Section {
                    Button {
                        signInput()
                    } label: {
                        Text("Sign message")
                            .modifier(TextButton())
                            .frame(maxWidth: .infinity, maxHeight: 32)
                    }
                    .alert(isPresented: $showError) {
                        Alert(
                            title: Text("Error"),
                            message: Text(errorMessage)
                        )
                    }
                    .modifier(ButtonStyle())
                }
            }
        }
    }

    func signInput() {
        let from = ethereum.selectedAddress
        let params: [String] = [from, message]
        let signRequest = EthereumRequest(
            method: .ethSignTypedDataV4,
            params: params
        )

        ethereum.request(signRequest)?.sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error):
                errorMessage = error.localizedDescription
                showError = true
                print("Error: \(errorMessage)")
            default: break
            }
        }, receiveValue: { value in
            self.result = value as? String ?? ""
        }).store(in: &cancellables)
    }
}

struct SignView_Previews: PreviewProvider {
    static var previews: some View {
        SignView()
    }
}
