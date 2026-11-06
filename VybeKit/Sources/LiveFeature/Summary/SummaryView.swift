import Components
import Design
import Models
import SwiftUI

/// Layout only: every value comes from `SummaryViewModel`, every tap goes to it.
struct SummaryView: View {
    @State private var viewModel: SummaryViewModel
    /// The counters start at zero and roll once to their values (`.numericText`).
    @State private var rolled = false
    @ScaledMetric(relativeTo: .body) private var photoSize = 100.0

    init(viewModel: SummaryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state) { _ in
            content
        } placeholder: {
            Text(verbatim: "Summary placeholder").font(Theme.Font.title).padding(Theme.Spacing.large)
        } empty: {
            EmptyView()
        }
        .background(Theme.Color.surface)
        .navigationBarBackButtonHidden(true)                  // the run has ended: no way back to the live screen
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
            withVybeAnimation(Theme.Motion.gentle) { rolled = true }   // a plain fade with Reduce Motion
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text(verbatim: SummaryText.title)
                        .font(Theme.Font.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: viewModel.visitedText)
                        .font(Theme.Font.title3)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                counters
                photoSection
            }
            .padding(Theme.Spacing.large)
        }
        .safeAreaInset(edge: .bottom) { buttons }
    }

    private var counters: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.large) {
            counter(SummaryText.spotsLabel, value: "\(rolled ? viewModel.visitedCount : 0)")
            counter(SummaryText.distanceLabel, value: rolled ? viewModel.distanceText : SummaryText.about("0"))
            if let duration = viewModel.durationText {
                counter(SummaryText.timeLabel, value: duration)
            }
        }
    }

    private func counter(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            Text(verbatim: value)
                .font(Theme.Font.title2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.Color.textPrimary)
                .contentTransition(.numericText())
            Text(verbatim: label)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: SummaryText.photosHeader)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if viewModel.photoURLs.isEmpty {
                Text(verbatim: SummaryText.noPhotos)
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: photoSize), spacing: Theme.Spacing.small)],
                          spacing: Theme.Spacing.small) {
                    ForEach(viewModel.photoURLs, id: \.id) { photo in
                        ZStack(alignment: .topTrailing) {
                            PlaceImage(url: photo.url, aspectRatio: 1)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                            Button { viewModel.removePhoto(photo.id) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Theme.Color.onPhoto, Theme.Color.scrim)
                                    .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                            }
                            .accessibilityLabel(Text(verbatim: SummaryText.removePhoto))
                        }
                    }
                }
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: Theme.Spacing.small) {
            if let reason = viewModel.postBlockedReason {
                Text(verbatim: reason)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            PrimaryButton(verbatim: SummaryText.post) { viewModel.postTapped() }
                .disabled(!viewModel.canPost)
                .accessibilityIdentifier("live.summary.post")
            Button(SummaryText.notNow) { viewModel.notNowTapped() }
                .font(Theme.Font.body)
                .tint(Theme.Color.accent)
                .frame(minHeight: Theme.Size.minTapTarget)
                .accessibilityIdentifier("live.summary.notNow")
        }
        .padding(Theme.Spacing.large)
        .background(.bar)
    }
}
