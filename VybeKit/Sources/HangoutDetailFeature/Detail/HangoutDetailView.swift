import Components
import Design
import SwiftUI

/// Layout only: every value comes from `HangoutDetailViewModel`, every tap goes to it.
struct HangoutDetailView: View {
    @State private var viewModel: HangoutDetailViewModel

    init(viewModel: HangoutDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { content in
            loaded(content)
        } placeholder: {
            DetailPlaceholder()
        } empty: {
            EmptyStateView(systemImage: "mappin.slash", message: HangoutDetailText.notFound)
        }
        .background(Theme.Color.surface)
        .navigationBarTitleDisplayMode(.inline)
        .vybeZoomDestination(sourceID: viewModel.id)     // zooms in from the Hangout card (MOTION moment 2)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }

    private func loaded(_ content: HangoutDetailContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                if !content.photos.isEmpty {
                    PhotoGallery(photos: content.photos)
                }
                DetailHeader(content: content)
                if content.hasTrek {
                    SafetyNote(HangoutDetailText.trekSafety, style: .warning)
                }
                if let credit = content.remixCredit {
                    Button(credit) { viewModel.remixCreditTapped() }
                        .font(Theme.Font.subheadline)
                        .foregroundStyle(Theme.Color.accent)
                }
                spotList(content.spots)
            }
            .padding(Theme.Spacing.large)
        }
        .safeAreaInset(edge: .bottom) { startBar }
        .toolbar { toolbar(content) }
    }

    private func spotList(_ spots: [HangoutDetailContent.SpotItem]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: HangoutDetailText.spotsHeader)
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            ForEach(spots) { item in
                Button { viewModel.spotTapped(item.placeID) } label: { SpotRow(item.row) }
                    .buttonStyle(.plain)
            }
        }
    }

    /// Start Hangout, pinned to the bottom. Its label and whether it works come from the ViewModel.
    private var startBar: some View {
        VStack(spacing: Theme.Spacing.small) {
            PrimaryButton(verbatim: startTitle, isLoading: viewModel.isStarting) {
                Task { await viewModel.startTapped() }
            }
            .disabled(!canStart)
            .vybeHaptic(.start, trigger: viewModel.startCount)
            .accessibilityIdentifier("hangoutDetail.start")
            if let note = startNote {
                Text(verbatim: note)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.Spacing.large)
        .background(.bar)
    }

    @ToolbarContentBuilder
    private func toolbar(_ content: HangoutDetailContent) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { Task { await viewModel.saveTapped() } } label: {
                Label(viewModel.isSaved ? HangoutDetailText.saved : HangoutDetailText.save,
                      systemImage: viewModel.isSaved ? "bookmark.fill" : "bookmark")
            }
            .vybeHaptic(.selection, trigger: viewModel.isSaved)
            ShareLink(item: content.shareText) {
                Label(HangoutDetailText.share, systemImage: "square.and.arrow.up")
            }
            Menu {
                Button(HangoutDetailText.remix, systemImage: "arrow.triangle.branch") { viewModel.remixTapped() }
                Button(HangoutDetailText.report, systemImage: "flag", role: .destructive) { viewModel.reportTapped() }
            } label: {
                Label(HangoutDetailText.more, systemImage: "ellipsis")
            }
        }
    }

    /// The Retry button on the error state.
    private func retry() { Task { await viewModel.reload() } }

    private var canStart: Bool { viewModel.startButton == .start || viewModel.startButton == .resume }

    private var startTitle: String {
        viewModel.startButton == .resume ? HangoutDetailText.resume : HangoutDetailText.start
    }

    private var startNote: String? {
        switch viewModel.startButton {
        case .start, .resume: viewModel.startError
        case .otherHangoutLive: HangoutDetailText.otherHangoutLive
        case .offline: HangoutDetailText.offline
        }
    }
}

/// Title with the Picks badge, the facts as pills, the tags and the summary.
private struct DetailHeader: View {
    let content: HangoutDetailContent

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                if content.isPick {
                    PickBadge()
                }
                Text(verbatim: content.title)
                    .font(Theme.Font.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
                InfoPill(icon: "indianrupeesign", text: content.budgetText)
                InfoPill(icon: "hourglass", text: content.durationText)
                if let bestTime = content.bestTimeText {
                    BestTimeLabel(bestTime)
                }
            }
            if !content.tags.isEmpty {
                TagRow(tags: content.tags)
            }
            Text(verbatim: content.summary)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
        }
    }
}

/// The greyed-out shape of the screen while it loads (`LoadStateView` redacts it).
private struct DetailPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Color.surfaceRaised)
                .aspectRatio(4 / 3, contentMode: .fit)
            Text(verbatim: "Hangout title placeholder").font(Theme.Font.title)
            Text(verbatim: "Budget · time · best time").font(Theme.Font.subheadline)
            Text(verbatim: "Summary placeholder text that fills about two lines on a phone.").font(Theme.Font.body)
            Spacer()
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
