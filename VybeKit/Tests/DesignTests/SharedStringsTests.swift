import Testing
@testable import Design

@MainActor
struct SharedStringsTests {
    @Test func sharedWordComesFromDesignCatalog() {
        #expect(SharedStrings.cancel == "Cancel")
    }
}
