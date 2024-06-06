//
//  URLOpener.swift
//

import UIKit

public protocol URLOpener {
    func open(_ url: URL)
}

public class DefaultURLOpener: URLOpener {
    public init() {}
    
    public func open(_ url: URL) {
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
}
