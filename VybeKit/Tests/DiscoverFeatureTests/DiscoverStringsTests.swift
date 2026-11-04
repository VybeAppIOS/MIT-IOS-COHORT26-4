import Design
import Testing
@testable import DiscoverFeature

@MainActor
struct DiscoverStringsTests {
    @Test func featureStringComesFromItsOwnCatalog() {
        #expect(DiscoverStrings.title == "Discover")
    }

    @Test func featureCanUseSharedWordFromDesign() {
        #expect(SharedStrings.cancel == "Cancel")
    }
}
