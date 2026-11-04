import Foundation
import Testing
@testable import Models

struct StateTests {
    @Test func loadStateIsEquatableWhenContentIs() {
        #expect(LoadState<String>.loading == .loading)
        #expect(LoadState<String>.loaded("a") == .loaded("a", isStale: false))
        #expect(LoadState<String>.loaded("a") != .loaded("a", isStale: true))
        #expect(LoadState<String>.failed(.offline) == .failed(.offline))
        #expect(LoadState<String>.empty != .loading)
    }

    @Test func pageRoundTrips() throws {
        let page = Page(items: [1, 2, 3], nextCursor: "abc")
        let data = try JSONCoding.encoder.encode(page)
        #expect(try JSONCoding.decoder.decode(Page<Int>.self, from: data) == page)
        #expect(Page<Int>(items: []).nextCursor == nil)
    }

    @Test func appErrorMapsOtherErrors() {
        #expect(AppError(AppError.notFound) == .notFound)
        #expect(AppError(URLError(.notConnectedToInternet)) == .offline)
        #expect(AppError(URLError(.timedOut)) == .unknown)
        #expect(AppError(CocoaError(.fileNoSuchFile)) == .unknown)
    }

    @Test func appErrorHasFriendlyMessages() {
        #expect(AppError.notFound.message == "This is no longer available.")
        #expect(AppError.offline.message == "You're offline. Check your connection and try again.")
        #expect(AppError.unknown.message == "Something went wrong. Please try again.")
        #expect(AppError.invalid("Add at least 2 Spots").message == "Add at least 2 Spots")
    }
}
