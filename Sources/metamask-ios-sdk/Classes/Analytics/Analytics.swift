//
//  Analytics.swift
//

import Foundation

public protocol Tracking {
    var enableDebug: Bool { get set }
    func trackEvent(_ event: Event, parameters: [String: Any]) async
}

public class Analytics: Tracking {
    private let network: any Networking
    private var debug: Bool!

    public var enableDebug: Bool {
        get { debug }
        set { debug = newValue }
    }

    convenience init(debug: Bool) {
        self.init(network: Network(), debug: debug)
    }

    public init(network: any Networking, debug: Bool) {
        self.debug = debug
        self.network = network
    }

    public func trackEvent(_ event: Event, parameters: [String: Any]) async {
        if !debug { return }

        var params = parameters
        params["event"] = event.name
        Logging.log("Analytics:: \(params)")

        do {
            try await network.post(params, endpoint: .analytics)
        } catch {
            Logging.error("tracking error: \(error.localizedDescription)")
        }
    }
}

extension Analytics {
    static let live = Dependencies.shared.tracker
}
