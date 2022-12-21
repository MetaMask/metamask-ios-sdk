//
//  SignView.swift
//  metamask-ios-sdk_Example
//
//  Created by Mpendulo Ndlovu on 2022/12/06.
//

import SwiftUI
import Combine
import metamask_ios_sdk

struct SignView: View {
    @ObservedObject var ethereum: Ethereum = Ethereum.shared
    
    @State var textValue = "{\"domain\":{\"chainId\":1,\"name\":\"Ether Mail\",\"verifyingContract\":\"0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC\",\"version\":\"1\"},\"message\":{\"contents\":\"Hello, Bob!\",\"from\":{\"name\":\"Cow\",\"wallets\":[\"0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826\",\"0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF\"]},\"to\":[{\"name\":\"Bob\",\"wallets\":[\"0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB\",\"0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57\",\"0xB0B0b0b0b0b0B000000000000000000000000000\"]}]},\"primaryType\":\"Mail\",\"types\":{\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}],\"Group\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"members\",\"type\":\"Person[]\"}],\"Mail\":[{\"name\":\"from\",\"type\":\"Person\"},{\"name\":\"to\",\"type\":\"Person[]\"},{\"name\":\"contents\",\"type\":\"string\"}],\"Person\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"wallets\",\"type\":\"address[]\"}]}}"
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State var result: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            Form {
                Section {
                    Text("Input")
                    TextEditor(text: $textValue)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .frame(height: geometry.size.height / 2)
                        .modifier(TextCurvature())
                }
                
                Section {
                    Text("Output")
                    TextEditor(text: $result)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .frame(minHeight: 60)
                        .modifier(TextCurvature())
                }
                
                Section {
                    Button {
                        signInput()
                    } label: {
                        Text("Sign Text")
                            .frame(maxWidth: .infinity, maxHeight: 32)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .background(Color.blue.grayscale(0.5))
                    .modifier(ButtonCurvature())
                }
            }
        }
    }
    
    func signInput() {
        let from = ethereum.selectedAddress
        let params: [String] = [from, textValue]
        let signRequest = EthereumRequest(
            method: .signTypedDataV4,
            params: params)
        
        ethereum.request(signRequest)?.sink { value in
            self.result = value
        }
        .store(in: &cancellables)
    }
}

struct SignView_Previews: PreviewProvider {
    static var previews: some View {
        SignView()
    }
}
