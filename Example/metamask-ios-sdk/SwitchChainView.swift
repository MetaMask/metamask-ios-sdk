//
//  SwitchChainView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import Combine
import metamask_ios_sdk

struct SwitchChainView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var ethereum: Ethereum = MMSDK.shared.ethereum

    @State private var cancellables: Set<AnyCancellable> = []
    @State private var chainId = ""
    @State private var chainName = ""
    @State private var chainUrls = ""
    @State private var alert: AlertInfo?

    struct AlertInfo: Identifiable {
        enum Status {
            case error
            case success
            case chainDoesNotExist
        }

        let id: Status
        let title: String
        let message: String

        var primaryButton: Alert.Button?
        var secondarButton: Alert.Button?
        var dismissButton: Alert.Button?
    }

    var body: some View {
        Form {
            Section {
                Text("Chain info")
                    .modifier(TextCallout())
                TextField("Chain name", text: $chainName)
                    .modifier(TextCaption())
                    .frame(minHeight: 32)
                    .modifier(TextCurvature())
                TextField("Chain ID", text: $chainId)
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
                .alert(item: $alert, content: { info in
                    if let _ = info.dismissButton {
                        return Alert(
                            title: Text(info.title),
                            message: Text(info.message),
                            dismissButton: info.dismissButton
                        )
                    } else {
                        return Alert(
                            title: Text(info.title),
                            message: Text(info.message),
                            primaryButton: info.primaryButton!,
                            secondaryButton: info.secondarButton!
                        )
                    }
                })
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
                if error.codeType == .unrecognizedChainId || error.codeType == .serverError {
                    alert = AlertInfo(
                        id: .chainDoesNotExist,
                        title: "Error",
                        message: "\(chainName) (\(chainId)) has not been added to your MetaMask wallet. Add chain?",
                        primaryButton: SwiftUI.Alert.Button.default(Text("OK"), action: {
                            addEthereumChain()
                        }),
                        secondarButton: SwiftUI.Alert.Button.default(Text("Cancel"))
                    )
                } else {
                    alert = AlertInfo(
                        id: .error,
                        title: "Error",
                        message: error.localizedDescription,
                        dismissButton: SwiftUI.Alert.Button.default(Text("OK"))
                    )
                    print("Switch chain error: \(error.localizedDescription)")
                }
            default: break
            }
        }, receiveValue: { value in
            alert = AlertInfo(
                id: .success,
                title: "Success",
                message: "Successfully switched to \(chainName)",
                dismissButton: SwiftUI.Alert.Button.default(Text("OK"), action: {
                    presentationMode.wrappedValue.dismiss()
                })
            )
            print("Switch chain result: \(value)")
        }).store(in: &cancellables)
    }

    func addEthereumChain() {
        /*
             For example for Polygon:
             chainId = "0x89"
             chainName = "Polygon"
             rpcUrls = ["https://polygon-rpc.com"]
         */
        let rpcUrls: [String] = chainUrls.components(separatedBy: ",") // expecting no whitespace after comma
        let addChainParams = AddChainRequest(
            chainId: chainId,
            chainName: chainName,
            rpcUrls: rpcUrls
        )

        let addChainRequest = EthereumRequest(
            method: .addEthereumChain,
            params: [addChainParams]
        )

        ethereum.request(addChainRequest)?.sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error):
                alert = AlertInfo(
                    id: .error,
                    title: "Error",
                    message: error.localizedDescription
                )
                print("Add chain error: \(error.localizedDescription)")
            default: break
            }
        }, receiveValue: { value in
            alert = AlertInfo(
                id: .success,
                title: "Success",
                message: ethereum.chainId == chainId ? "Successfully switched to \(chainName)" : "Successfully added \(chainName)",
                dismissButton: SwiftUI.Alert.Button.default(Text("OK"), action: {
                    presentationMode.wrappedValue.dismiss()
                })
            )
            print("Add chain result: \(value)")
        }).store(in: &cancellables)
    }

    // request structs need to implement `CodableData`
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
