//
//  TextStyle.swift
//  metamask-ios-sdk_Example
//

import SwiftUI

struct TextCaption: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.caption, design: .rounded))
            .foregroundColor(.black)
    }
}

struct TextCallout: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.callout, design: .rounded))
            .foregroundColor(.black)
    }
}

struct TextCalloutLight: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.callout, design: .rounded))
            .foregroundColor(.gray)
    }
}

struct TextButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .rounded))
            .foregroundColor(.white)
    }
}
