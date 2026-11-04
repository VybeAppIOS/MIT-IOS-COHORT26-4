import Foundation

/// One standard for a screen's FIRST load (`docs/adr/005-state-and-persistence.md`).
/// Once content is on screen, a failed refresh keeps it and sets `isStale`; cancellation never changes the state.
public enum LoadState<Content> {
    case loading
    case loaded(Content, isStale: Bool = false)
    case empty
    case failed(AppError)
}

extension LoadState: Sendable where Content: Sendable {}
extension LoadState: Equatable where Content: Equatable {}
