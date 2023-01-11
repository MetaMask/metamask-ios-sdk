//
//  ButtonStyle.swift
//  metamask-ios-sdk_Example
//

import SwiftUI

struct ButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3)
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(Color.blue.grayscale(0.5))
            .modifier(ButtonCurvature())
    }
}
