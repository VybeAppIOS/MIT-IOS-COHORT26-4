import Testing
@testable import Components
import Design

@MainActor
struct BadgesTests {
    @Test func everyStatusHasItsOwnWordsAndSymbol() {
        let titles = StatusBadge.Status.allCases.map(\.title)
        let symbols = StatusBadge.Status.allCases.map(\.systemImage)

        #expect(titles == ["Saved", "Draft", "Scheduled", "Live", "Done"])
        #expect(Set(symbols).count == symbols.count)
    }

    @Test func wordsComeFromTheCatalogNotTheKey() {
        #expect(SharedStrings.badgePicks == "Picks")
        #expect(SharedStrings.badgeClosed == "Closed by authorities")
        #expect(!SharedStrings.badgeLive.hasPrefix("component."))
    }
}
