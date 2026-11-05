import Components
import Design
import SwiftUI

/// Layout only: every value comes from `RemixTreeViewModel`, every tap goes to it.
struct RemixTreeView: View {
    @State private var viewModel: RemixTreeViewModel

    init(viewModel: RemixTreeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { content in
            loaded(content)
        } placeholder: {
            RemixPlaceholder()
        } empty: {
            EmptyStateView(systemImage: "mappin.slash", message: HangoutDetailText.notFound)
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: RemixTreeText.title))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }

    private func loaded(_ content: RemixTreeContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                if let counters = content.counterText {
                    Text(verbatim: counters)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .accessibilityIdentifier("hangoutDetail.remixTree.counters")
                }
                if let original = content.original {
                    section(RemixTreeText.remixedFromHeader) {
                        if let credit = content.originalCredit {
                            Text(verbatim: credit)
                                .font(Theme.Font.subheadline)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                        HangoutCard(original, style: .compact) { viewModel.hangoutTapped(original.id) }
                    }
                }
                section(RemixTreeText.remixesHeader) {
                    if content.remixes.isEmpty {
                        Text(verbatim: RemixTreeText.empty)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textSecondary)
                    } else {
                        ForEach(content.remixes) { item in
                            RemixRow(item: item) { viewModel.hangoutTapped(item.id) }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.large)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: title)
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    /// The Retry button on the error state.
    private func retry() { Task { await viewModel.reload() } }
}

/// One Remix: the remixer's avatar, name and @username, then the Remix's card.
private struct RemixRow: View {
    let item: RemixTreeContent.RemixItem
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            if let name = item.authorName {
                HStack(spacing: Theme.Spacing.small) {
                    Avatar(url: item.authorPhotoURL, name: name, size: .small)
                    VStack(alignment: .leading) {
                        Text(verbatim: name)
                            .font(Theme.Font.subheadline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        if let username = item.authorUsername {
                            Text(verbatim: username)
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
            }
            HangoutCard(item.card, style: .compact, action: onTap)
        }
    }
}

/// The greyed-out shape of the screen while it loads (`LoadStateView` redacts it).
private struct RemixPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            Text(verbatim: "Done 00× · Remixed 00×").font(Theme.Font.headline)
            Text(verbatim: "Remixed from").font(Theme.Font.title3)
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Color.surfaceRaised)
                .frame(height: Theme.Spacing.huge * 3)
            Text(verbatim: "Remixes").font(Theme.Font.title3)
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Color.surfaceRaised)
                .frame(height: Theme.Spacing.huge * 3)
            Spacer()
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
