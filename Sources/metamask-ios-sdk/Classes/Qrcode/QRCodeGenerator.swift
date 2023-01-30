//
//  QRCodeGenerator.swift
//  metamask-ios-sdk
//

import SwiftUI
import CoreImage.CIFilterBuiltins

public func generateQRCode(from url: String) -> UIImage? {
    let data = Data(url.utf8)

    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.setValue(data, forKey: "inputMessage")

    guard
        let qrCodeCIImage = filter.outputImage,
        let qrCodeCGImage = context.createCGImage(qrCodeCIImage, from: qrCodeCIImage.extent)
    else { return nil }

    return UIImage(cgImage: qrCodeCGImage)
}
