//
//  ViewExtension.swift
//  metamask-ios-sdk_Example
//

import SwiftUI

extension View {
    func toast<ToastContent: View>(isPresented: Binding<Bool>, @ViewBuilder content: () -> ToastContent) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                ToastOverlay(content: content(), isPresented: isPresented)
            }
        }
    }
}
