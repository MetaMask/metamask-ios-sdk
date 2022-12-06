//
//  SignView.swift
//  metamask-ios-sdk_Example
//
//  Created by Mpendulo Ndlovu on 2022/12/06.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI
import metamask_ios_sdk

struct SignView: View {
    @ObservedObject var ethereum: Ethereum = Ethereum.shared
    
    @State var textValue = "{\"domain\":{\"chainId\":1,\"name\":\"Ether Mail\",\"verifyingContract\":\"0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC\",\"version\":\"1\"},\"message\":{\"contents\":\"Hello, Bob!\",\"from\":{\"name\":\"Cow\",\"wallets\":[\"0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826\",\"0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF\"]},\"to\":[{\"name\":\"Bob\",\"wallets\":[\"0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB\",\"0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57\",\"0xB0B0b0b0b0b0B000000000000000000000000000\"]}]},\"primaryType\":\"Mail\",\"types\":{\"EIP712Domain\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"chainId\",\"type\":\"uint256\"},{\"name\":\"verifyingContract\",\"type\":\"address\"}],\"Group\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"members\",\"type\":\"Person[]\"}],\"Mail\":[{\"name\":\"from\",\"type\":\"Person\"},{\"name\":\"to\",\"type\":\"Person[]\"},{\"name\":\"contents\",\"type\":\"string\"}],\"Person\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"wallets\",\"type\":\"address[]\"}]}}"
    
    var sign: ((String) -> Void)?
    
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Input")
                    TextEditor(text: $textValue)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 2) {
                    Text("Output")
                    TextEditor(text: $ethereum.response)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                        .disabled(true)
                }
                
                Button {
                    signInput()
                } label: {
                    Text("Sign Text")
                        .frame(maxWidth: .infinity, maxHeight: 38)
                }
                .font(.title3)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .background(Color.blue.grayscale(0.5))
                .cornerRadius(20)
                .padding(.horizontal, 16)
            }
            .padding(EdgeInsets(top: 42, leading: 0, bottom: 32, trailing: 0))
        }
        .background(Color.orange.grayscale(0.9))
        .ignoresSafeArea()
    }
    
    func signInput() {
        let from = ethereum.selectedAddress
        let params: [String] = [from, textValue]
        let signRequest = EthereumRequest(
            method: .signTypedDataV4,
            params: params)
        
        ethereum.request(signRequest)
    }
}

struct SignView_Previews: PreviewProvider {
    static var previews: some View {
        SignView(sign: nil)
    }
}
