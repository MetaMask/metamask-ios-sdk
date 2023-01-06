//
//  Analytics.swift
//

import Foundation

protocol Tracking {
    var enableDebug: Bool { get set }
    func trackEvent(_ event: Event, parameters: [String: Any]) async
}

class Analytics: Tracking {
    private let network: Network
    private var debug: Bool!

    var enableDebug: Bool {
        get { debug }
        set { debug = newValue }
    }

    convenience init(debug: Bool) {
        self.init(network: Network(), debug: debug)
    }

    init(network: Network, debug: Bool) {
        self.debug = debug
        self.network = network
    }

    func trackEvent(_ event: Event, parameters: [String: Any]) async {
        if !debug { return }

        var params = parameters
        params["event"] = event.name

        do {
            try await network.post(params, endpoint: .analytics)
        } catch {
            Logging.error("tracking error: \(error.localizedDescription)")
        }
    }
}
