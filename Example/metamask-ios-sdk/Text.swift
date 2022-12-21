//
//  Text.swift
//  metamask-ios-sdk_Example
//

import SwiftUI

struct TextCaption: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .background(Color.white)
            .foregroundColor(.black)
    }
}
