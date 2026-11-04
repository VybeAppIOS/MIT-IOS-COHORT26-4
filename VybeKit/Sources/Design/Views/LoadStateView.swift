import Models
import SwiftUI

/// The one standard way to draw a screen's first load (`docs/ARCHITECTURE.md` 2.5, ADR 005):
/// - `.loading`: the caller's placeholder, greyed out (`.redacted(reason: .placeholder)`); VoiceOver says "Loading".
/// - `.loaded`: the content. When `isStale` is true, `OfflineBanner` is shown above it.
/// - `.empty`: the caller's `EmptyStateView` (or any view).
/// - `.failed`: `ErrorView` with the error's friendly message and Retry (only when `onRetry` is given).
///
/// Stale content is not made read-only here: a screen applies `.offlineReadOnly(_:)` where it fits.
public struct LoadStateView<Content, Loaded: View, Placeholder: View, Empty: View>: View {
    private let state: LoadState<Content>
    private let onRetry: (() -> Void)?
    private let content: (Content) -> Loaded
    private let placeholder: () -> Placeholder
    private let empty: () -> Empty

    public init(
        _ state: LoadState<Content>,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Content) -> Loaded,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder empty: @escaping () -> Empty
    ) {
        self.state = state
        self.onRetry = onRetry
        self.content = content
        self.placeholder = placeholder
        self.empty = empty
    }

    /// Which of the four looks is shown. Internal so tests can check it without rendering.
    enum Phase: Equatable {
        case loading
        case loaded(showsOfflineBanner: Bool)
        case empty
        case failed(AppError)
    }

    var phase: Phase {
        switch state {
        case .loading: .loading
        case .loaded(_, let isStale): .loaded(showsOfflineBanner: isStale)
        case .empty: .empty
        case .failed(let error): .failed(error)
        }
    }

    public var body: some View {
        switch phase {
        case .loading:
            placeholder()
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(StateViewText.loading))
        case .loaded(let showsOfflineBanner):
            if case .loaded(let value, _) = state {
                VStack(spacing: 0) {
                    if showsOfflineBanner {
                        OfflineBanner()
                    }
                    content(value)
                }
            }
        case .empty:
            empty()
        case .failed(let error):
            ErrorView(error, onRetry: onRetry)
        }
    }
}

/// Text for the state views, read from Design's own catalog (`bundle: #bundle`, task X-3).
enum StateViewText {
    static var loading: String { String(localized: "design.loading", bundle: #bundle) }
    static var retry: String { String(localized: "common.retry", bundle: #bundle) }
    static var offlineBanner: String { String(localized: "design.offlineBanner", bundle: #bundle) }
}

#if DEBUG
/// Preview content: the EXAMPLE Hangout titles from `Models/Samples` (never invented venues).
private struct PreviewList: View {
    let titles: [String]

    var body: some View {
        List(titles, id: \.self) { title in
            Text(title).font(Theme.Font.body)
        }
    }
}

private let sampleTitles = SampleData.hangouts.map(\.title)
private let neutralRows = ["Hangout title", "Hangout title", "Hangout title"]

private let previewRetry: () -> Void = {}

private func previewScreen(_ state: LoadState<[String]>, emptyAction: Bool = true) -> some View {
    LoadStateView(state, onRetry: previewRetry) { titles in
        PreviewList(titles: titles)
    } placeholder: {
        PreviewList(titles: neutralRows)
    } empty: {
        EmptyStateView(systemImage: "map", message: "No Hangouts here yet.",
                       actionTitle: emptyAction ? "Start Hangout" : nil, action: emptyAction ? {} : nil)
    }
}

#Preview("Loading") { previewScreen(.loading) }
#Preview("Loaded") { previewScreen(.loaded(sampleTitles)) }
#Preview("Stale (offline banner)") { previewScreen(.loaded(sampleTitles, isStale: true)) }
#Preview("Empty, with action") { previewScreen(.empty) }
#Preview("Empty, no action") { previewScreen(.empty, emptyAction: false) }
#Preview("Error") { previewScreen(.failed(.unknown)) }
#Preview("Error, offline") { previewScreen(.failed(.offline)) }
#Preview("Large text, stale") { previewScreen(.loaded(sampleTitles, isStale: true)).dynamicTypeSize(.accessibility3) }
#Preview("Large text, error") { previewScreen(.failed(.unknown)).dynamicTypeSize(.accessibility3) }
#endif
