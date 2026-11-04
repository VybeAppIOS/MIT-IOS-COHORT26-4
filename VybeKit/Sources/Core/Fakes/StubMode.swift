#if DEBUG
import Foundation
import Models

/// How a stub repository behaves, so previews and tests can show every screen state.
public enum StubMode: Hashable, Sendable, CaseIterable {
    /// Returns the sample data.
    case loaded
    /// Returns nothing.
    case empty
    /// Throws `AppError.offline`.
    case failing
    /// Never answers (the loading state); stops when its task is cancelled.
    case neverReturns

    /// Runs a stub call in this mode.
    func run<T: Sendable>(loaded: T, empty: T) async throws -> T {
        switch self {
        case .loaded: return loaded
        case .empty: return empty
        case .failing: throw AppError.offline
        case .neverReturns:
            try await Task.sleep(for: .seconds(60 * 60 * 24 * 365))
            throw CancellationError()
        }
    }
}
#endif
