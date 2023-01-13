//
//  SwitchChainView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import Combine
import metamask_ios_sdk

struct SwitchChainView: View {
    @ObservedObject var ethereum: Ethereum = MMSDK.shared.ethereum

    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showUnauthorisedRequestError = false
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var chainId = ""
    @State private var chainName = ""
    @State private var chainUrls = ""

    var body: some View {
        Form {
            Section {
                Text("Chain info")
                    .modifier(TextCallout())
                TextField("Chain ID", text: $chainId)
                    .modifier(TextCaption())
                    .frame(minHeight: 32)
                    .modifier(TextCurvature())
                
                TextField("Chain name", text: $chainName)
                    .modifier(TextCaption())
                    .frame(minHeight: 32)
                    .modifier(TextCurvature())
                
                TextField("Chain url(s) (comma separated)", text: $chainUrls)
                    .modifier(TextCaption())
                    .frame(minHeight: 32)
                    .modifier(TextCurvature())
            }

            Section {
                Button {
                    switchEthereumChain()
                } label: {
                    Text("Switch Chain ID")
                        .modifier(TextButton())
                        .frame(maxWidth: .infinity, maxHeight: 32)
                }
                .alert(isPresented: $showError) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage)
                    )
                }
                .alert(isPresented: $showUnauthorisedRequestError) {
                    Alert(
                        title: Text("Error"),
                        message: Text("\(chainName) (\(chainId)) has not been added to your MetaMask wallet. Add chain?"),
                        primaryButton: SwiftUI.Alert.Button.default(Text("OK"), action: {
                            addEthereumChain()
                        }),
                        secondaryButton: SwiftUI.Alert.Button.default(Text("Cancel")))
                }
                .modifier(ButtonStyle())
            }
        }
        .background(Color.blue.grayscale(0.5))
    }

    func switchEthereumChain() {
        let switchChainParams: [String: String] = [
            "chainId": chainId
        ]
        let switchChainRequest = EthereumRequest(
            method: .switchEthereumChain,
            params: [switchChainParams]
        )

        ethereum.request(switchChainRequest)?.sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error):
                if error.codeType == .unrecognizedChainId || error.codeType == .internalServerError {
                    showUnauthorisedRequestError = true
                } else {
                    errorMessage = error.localizedDescription
                    showError = true
                    print("Error: \(errorMessage)")
                }
            default: break
            }
        }, receiveValue: { value in
            print("Result: \(value)")
        }).store(in: &cancellables)
    }
    
    func addEthereumChain() {
        /*
             For example for Polygon:
             chainId = "0x89"
             chainName = "Polygon"
             rpcUrls = ["https://polygon-rpc.com"]
         */
        let rpcUrls: [String] = chainUrls.components(separatedBy: ",") // no whitespace after comma
        let addChainParams = AddChainRequest(
            chainId: chainId,
            chainName: chainName,
            rpcUrls: rpcUrls)
        
        let addChainRequest = EthereumRequest(
            method: .addEthereumChain,
            params: [addChainParams]
        )

        ethereum.request(addChainRequest)?.sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error):
                errorMessage = error.localizedDescription
                showError = true
                print("Error: \(errorMessage)")
            default: break
            }
        }, receiveValue: { value in
            print("Result: \(value)")
        }).store(in: &cancellables)
    }
    
    struct AddChainRequest: CodableData {
        let chainId: String
        let chainName: String
        let rpcUrls: [String]
        
        public func socketRepresentation() -> NetworkData {
            [
                "chainId": chainId,
                "chainName": chainName,
                "rpcUrls": rpcUrls
            ]
        }
    }
}

struct SwitchChainView_Previews: PreviewProvider {
    static var previews: some View {
        SwitchChainView()
    }
}
