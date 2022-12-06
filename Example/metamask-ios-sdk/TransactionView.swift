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
    
    @State private var to: String = "0xd0059fB234f15dFA9371a7B45c09d451a2dd2B5a"
    @State private var amount: String = "0x0"
    
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                Spacer()

                Group {
                    VStack(spacing: 2) {
                        Text("From")
                            .foregroundColor(.black)
                        TextEditor(text: $ethereum.selectedAddress)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 2) {
                        Text("To")
                        Text(to)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 2) {
                        Text("Amount")
                        TextEditor(text: $amount)
                            .frame(height: 38)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 2) {
                        Text("Result")
                        TextEditor(text: $ethereum.response)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                            .disabled(true)
                    }
                }
                
                Button {
                    sendTransaction()
                } label: {
                    Text("Send Transaction")
                        .frame(maxWidth: .infinity, maxHeight: 38)
                }
                .font(.title3)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color.blue.grayscale(0.5))
                .cornerRadius(20)
                .padding(.horizontal, 16)
            }
            .padding(EdgeInsets(top: 42, leading: 0, bottom: 32, trailing: 0))
        }
        .background(Color.orange.grayscale(0.9))
        .ignoresSafeArea()
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
