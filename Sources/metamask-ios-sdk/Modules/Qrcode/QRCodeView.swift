//
//  QRCodeView.swift
//

import SwiftUI

public struct QRCodeView: View {
    let url: String
    private let metamaskTint = Color(red: 241/255, green: 215/255, blue: 181/255)
    
    public init(url: String) {
        self.url = url
    }
    
    public var body: some View {
        if let image = generateQRCode(from: url) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .frame(
                    width: 200,
                    height: 200,
                    alignment: .center)
                .colorMultiply(metamaskTint)
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(url: "https://metamask.io/sdk/")
    }
}
