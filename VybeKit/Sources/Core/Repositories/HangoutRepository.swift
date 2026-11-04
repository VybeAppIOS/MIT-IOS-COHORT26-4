import Foundation
import Models

/// Counts the server keeps (not part of `Hangout`).
public struct HangoutStats: Hashable, Sendable {
    public var doneCount: Int
    public var remixCount: Int

    public init(doneCount: Int, remixCount: Int) {
        self.doneCount = doneCount
        self.remixCount = remixCount
    }
}

/// Where Hangouts come from: bundled JSON now (LocalData), a server later (Remote). Screens never know which.
/// Not main-actor (ADR 001): calls run off the main thread. Errors are `AppError`s; a missing ID is `.notFound`.
public protocol HangoutRepository: Sendable {
    func hangout(id: HangoutID) async throws -> Hangout
    /// Published Hangouts, nearest first when `center` is given, matching `filters`.
    func hangouts(near center: Coordinate?, filters: HangoutFilters) async throws -> [Hangout]
    /// Picks: Hangouts the Vybe team has done and posted.
    func picks() async throws -> [Hangout]
    func remixes(of id: HangoutID) async throws -> [Hangout]
    func stats(for id: HangoutID) async throws -> HangoutStats
}
