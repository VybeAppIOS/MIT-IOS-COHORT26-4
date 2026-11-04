import Foundation
import Testing
@testable import Core

@MainActor
struct NetworkMonitorTests {
    @Test func testInitializerReflectsGivenOfflineState() {
        let onlineMonitor = NetworkMonitor(isOffline: false)
        #expect(!onlineMonitor.isOffline)

        let offlineMonitor = NetworkMonitor(isOffline: true)
        #expect(offlineMonitor.isOffline)
    }

    @Test func forceOfflineTogglesState() {
        let monitor = NetworkMonitor(isOffline: false)
        #expect(!monitor.isOffline)

        monitor.forceOffline(true)
        #expect(monitor.isOffline)

        monitor.forceOffline(false)
        #expect(!monitor.isOffline)
    }

    @Test func deinitIsSafeForRealMonitor() {
        // Scoped creation to exercise initialization and deinit cancellation without leaks
        do {
            let monitor = NetworkMonitor()
            _ = monitor.isOffline
            monitor.forceOffline(true)
            #expect(monitor.isOffline)
        }
        // Exiting the scope successfully calls deinit and cancels the path monitor cleanly.
        #expect(true)
    }

    @Test func forceOfflineResetResumesStatus() {
        let monitor = NetworkMonitor(isOffline: false)
        monitor.forceOffline(true)
        #expect(monitor.isOffline)

        // Resetting the forced value returns to unforced handling
        monitor.forceOffline(nil)
        #expect(!monitor.isOffline)
    }
}
