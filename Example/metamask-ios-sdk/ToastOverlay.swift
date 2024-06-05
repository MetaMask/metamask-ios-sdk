//
//  ToastOverlay.swift
//  metamask-ios-sdk_Example
//

import SwiftUI

struct ToastOverlay<ToastContent>: View where ToastContent: View {
    let content: ToastContent
    @Binding var isPresented: Bool

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack {
                     Spacer()
                    content
                        .frame(width: geometry.size.width * 0.8, height: 8)
                        .animation(.easeIn)
                     Spacer()
                 }
                Spacer()
            }
        }
        .background(Color.clear)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isPresented = false
            }
        }
    }
}
