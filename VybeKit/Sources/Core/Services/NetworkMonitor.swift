import Foundation
import Network
import Observation

/// Monitors network reachability and exposes `isOffline` for screens and the offline banner.
/// `@MainActor` because UI views and view models observe `isOffline` directly (ADR 001).
@MainActor @Observable
public final class NetworkMonitor {
    public private(set) var isOffline: Bool

    private var forcedOffline: Bool?
    private var baseOfflineState: Bool
    private let monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "com.vybe.networkmonitor", qos: .utility)

    /// Production initializer that starts monitoring via `NWPathMonitor`.
    public init() {
        self.isOffline = false
        self.baseOfflineState = false
        let pathMonitor = NWPathMonitor()
        self.monitor = pathMonitor

        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.handlePathUpdate(path)
            }
        }
        pathMonitor.start(queue: queue)
    }

    /// Testing/preview initializer that does not start a real network monitor.
    public init(isOffline: Bool) {
        self.isOffline = isOffline
        self.baseOfflineState = isOffline
        self.forcedOffline = nil
        self.monitor = nil
    }

    deinit {
        monitor?.cancel()
    }

    /// Overrides the network status for tests, previews and desk demos.
    /// Pass `nil` to resume following real network path updates.
    public func forceOffline(_ forced: Bool?) {
        self.forcedOffline = forced
        if let forced {
            self.isOffline = forced
        } else if let monitor {
            self.isOffline = (monitor.currentPath.status != .satisfied)
        } else {
            self.isOffline = baseOfflineState
        }
    }

    private func handlePathUpdate(_ path: NWPath) {
        let isUnsatisfied = (path.status != .satisfied)
        baseOfflineState = isUnsatisfied
        if let forced = forcedOffline {
            isOffline = forced
        } else {
            isOffline = isUnsatisfied
        }
    }
}
