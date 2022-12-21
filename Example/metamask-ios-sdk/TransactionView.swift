//
//  TransactionView.swift
//  metamask-ios-sdk_Example
//
//  Created by Mpendulo Ndlovu on 2022/12/06.
//

import SwiftUI
import Combine
import metamask_ios_sdk

struct TransactionView: View {
    @ObservedObject var ethereum: Ethereum = Ethereum.shared
    
    @State private var amount = "0x0"
    @State var result: String = ""
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var to = "0xd0059fB234f15dFA9371a7B45c09d451a2dd2B5a"
    
    var body: some View {
        Form {
            Section {
                Text("From")
                TextEditor(text: $ethereum.selectedAddress)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .frame(minHeight: 60)
                    .modifier(TextCurvature())
            }
            
            Section {
                Text("To")
                TextEditor(text: $to)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .frame(minHeight: 60)
                    .modifier(TextCurvature())
                
            }
            
            Section {
                Text("Amount")
                TextEditor(text: $amount)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .frame(minHeight: 60)
                    .modifier(TextCurvature())
            }
            
            Section {
                Text("Result")
                TextEditor(text: $result)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .frame(minHeight: 60)
                    .modifier(TextCurvature())
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
                .modifier(ButtonCurvature())
            }
        }
        .background(Color.blue.grayscale(0.5))
    }
    
    func sendTransaction() {
        let transaction = Transaction(
            to: to,
            from: ethereum.selectedAddress,
            value: "0x0")
        
        let transactionRequest = EthereumRequest(
            method: .sendTransaction,
            params: [transaction])
        
        ethereum.request(transactionRequest)?.sink { value in
            self.result = value
        }
        .store(in: &cancellables)
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
    }
}
