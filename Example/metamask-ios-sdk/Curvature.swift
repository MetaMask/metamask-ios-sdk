//
//  Curvature.swift
//  metamask-ios-sdk_Example
//
//  Created by Mpendulo Ndlovu on 2022/12/19.
//

import SwiftUI

struct ContinuousCurvature: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.clear, lineWidth: 1)
            )
    }
}
