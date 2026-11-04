import Models
import SwiftUI
import Testing
@testable import Design

@MainActor
struct StateViewsTests {
    // Strings come from Design's catalog: real text, not the raw key.
    @Test func stateTextsResolveToRealText() {
        #expect(StateViewText.loading == "Loading")
        #expect(StateViewText.retry == "Retry")
        #expect(StateViewText.offlineBanner == "You're offline. Showing what you last saw.")
    }

    private func view(_ state: LoadState<String>) -> LoadStateView<String, Text, Text, Text> {
        LoadStateView(state) { Text($0) } placeholder: { Text("placeholder") } empty: { Text("empty") }
    }

    // The right look for each LoadState.
    @Test func eachLoadStateShowsTheRightPhase() {
        #expect(view(.loading).phase == .loading)
        #expect(view(.loaded("content")).phase == .loaded(showsOfflineBanner: false))
        #expect(view(.loaded("content", isStale: true)).phase == .loaded(showsOfflineBanner: true))
        #expect(view(.empty).phase == .empty)
        #expect(view(.failed(.offline)).phase == .failed(.offline))
        #expect(view(.failed(.notFound)).phase == .failed(.notFound))
    }
}
