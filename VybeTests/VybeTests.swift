import Testing
@testable import Vybe

/// Smoke test: proves the test target builds, links against the app and runs.
struct VybeTests {
    @MainActor
    @Test func rootViewCanBeCreated() {
        _ = RootView()
    }
}
