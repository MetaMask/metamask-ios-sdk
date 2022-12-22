//
//  Analytics.swift
//

import Foundation

public protocol Tracking {
    func trackEvent(_ event: Event, parameters: [String: Any]) async
}

public class Analytics: Tracking {
    private let network: Network
    private let debug: Bool
    
    public convenience init(debug: Bool = true) {
        self.init(network: Network(), debug: debug)
    }
    
    init(network: Network, debug: Bool) {
        self.debug = debug
        self.network = network
    }
    
    public func trackEvent(_ event: Event, parameters: [String: Any]) async {
        if !debug { return }
        
        var params = parameters
        params["event"] = event.rawValue
        do {
            try await network.post(params, endpoint: .analytics)
        } catch {
            Logging.error(error.localizedDescription)
        }
    }
}

public extension Analytics {
    static let debug: Tracking = Analytics(debug: true)
    static let release: Tracking = Analytics(debug: false)
}
