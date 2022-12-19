//
//  TransactionView.swift
//  metamask-ios-sdk_Example
//
//  Created by Mpendulo Ndlovu on 2022/12/06.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI
import metamask_ios_sdk

struct TransactionView: View {
    @ObservedObject var ethereum: Ethereum = Ethereum.shared
    
    @State private var to = "0xd0059fB234f15dFA9371a7B45c09d451a2dd2B5a"
    @State private var amount = "0x0"
    
    var body: some View {
        Form {
            Section {
                Text("From")
                    .foregroundColor(.black)
                TextEditor(text: $ethereum.selectedAddress)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .frame(minHeight: 40)
            }
            
            Section {
                Text("To")
                Text(to)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .padding(.horizontal)
            }
            
            Section {
                Text("Amount")
                Text(amount)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .padding(.horizontal)
            }
            
            Section {
                Text("Result")
                TextEditor(text: $ethereum.response)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .padding(.horizontal)
            }
            
            Section {
                Button {
                    sendTransaction()
                } label: {
                    Text("Send Transaction")
                        .frame(maxWidth: .infinity, maxHeight: 32)
                }
                .font(.title3)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color.blue.grayscale(0.5))
                .modifier(ContinuousCurvature())
            }
        }
    }
    
    func sendTransaction() {
        let transaction = Transaction(
            to: to,
            from: ethereum.selectedAddress,
            value: "0x0")
        let transactionRequest = EthereumRequest(
            method: .sendTransaction,
            params: [transaction])
        
        ethereum.request(transactionRequest)
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
    }
}
