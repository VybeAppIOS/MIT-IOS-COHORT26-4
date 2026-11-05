import Core
import Foundation
import Models

/// One blocked person, ready to draw.
struct BlockedRow: Identifiable, Equatable {
    let id: UserID
    let name: String
    /// "@sample.kabir"
    let username: String
    let photoURL: URL?
}

/// ST3, Blocked. The people I have blocked, each with Unblock. Unblocking tells the server first
/// (`SafetyRepository.unblock`), then the session (`session.unblock`), so every screen shows them again at once.
/// Offline, Unblock is off.
@MainActor @Observable
final class BlockedViewModel {
    private(set) var state: LoadState<[BlockedRow]> = .loading
    private(set) var unblockFailed = false
    /// The person being unblocked right now (their button shows progress).
    private(set) var unblocking: UserID?

    private let safety: any SafetyRepository
    private let session: SessionStore
    private let photos: any PhotoStore
    private let network: NetworkMonitor
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(safety: any SafetyRepository, session: SessionStore, photos: any PhotoStore, network: NetworkMonitor) {
        self.safety = safety
        self.session = session
        self.photos = photos
        self.network = network
    }

    var title: String { String(localized: "profile.blocked.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "profile.blocked.empty", bundle: #bundle) }
    var unblockTitle: String { String(localized: "profile.blocked.unblock", bundle: #bundle) }
    var footer: String { String(localized: "profile.blocked.footer", bundle: #bundle) }
    var errorText: String { String(localized: "profile.blocked.error", bundle: #bundle) }
    var offlineText: String { String(localized: "profile.blocked.offline", bundle: #bundle) }
    var isOffline: Bool { network.isOffline }
    var canUnblock: Bool { !isOffline && unblocking == nil }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        do {
            let rows = try await safety.blocked().map(row)
            state = rows.isEmpty ? .empty : .loaded(rows)
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            if case .loaded(let rows, _) = state {
                state = .loaded(rows, isStale: true)
            } else {
                state = .failed(AppError(error))
            }
        }
    }

    private func row(_ person: UserProfile) -> BlockedRow {
        BlockedRow(id: person.id, name: person.displayName, username: "@\(person.username)",
                   photoURL: person.photo.flatMap { photos.url(for: $0) })
    }

    // MARK: What the person does

    func unblockTapped(_ id: UserID) async {
        guard canUnblock else { return }
        unblocking = id
        defer { unblocking = nil }
        do {
            try await safety.unblock(id)
            session.unblock(id)
            unblockFailed = false
            if case .loaded(let rows, let isStale) = state {
                let remaining = rows.filter { $0.id != id }
                state = remaining.isEmpty ? .empty : .loaded(remaining, isStale: isStale)
            }
        } catch is CancellationError {
            return
        } catch {
            unblockFailed = true
        }
    }
}
