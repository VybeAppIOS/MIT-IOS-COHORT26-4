import Components
import Design
import MapKit
import SwiftUI

/// Layout only: every value comes from `SpotSheetViewModel`, every tap goes to it.
/// The one exception is Apple's place details (see `AppleDetailsButton`).
struct SpotSheetView: View {
    @State private var viewModel: SpotSheetViewModel

    init(viewModel: SpotSheetViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { content in
            loaded(content)
        } placeholder: {
            SpotPlaceholder()
        } empty: {
            EmptyStateView(systemImage: "mappin.slash", message: SpotSheetText.notFound)
        }
        .background(Theme.Color.surface)
        .navigationBarTitleDisplayMode(.inline)
        .presentationDetents([.medium, .large])
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }

    private func loaded(_ content: SpotSheetContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                if !content.photos.isEmpty {
                    PhotoGallery(photos: content.photos)
                }
                SpotHeader(content: content)
                if let trekNote = content.trekNote {
                    SafetyNote(trekNote, style: .warning)
                }
                if let applePlaceID = content.applePlaceID {
                    AppleDetailsButton(applePlaceID: applePlaceID)
                }
                if !content.hangouts.isEmpty {
                    hangoutList(content.hangouts)
                }
            }
            .padding(Theme.Spacing.large)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(SpotSheetText.reportPlace, systemImage: "flag", role: .destructive) {
                        viewModel.reportTapped()
                    }
                } label: {
                    Label(SpotSheetText.more, systemImage: "ellipsis")
                }
            }
        }
    }

    private func hangoutList(_ cards: [HangoutCardData]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: SpotSheetText.hangoutsHeader)
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            ForEach(cards) { card in
                HangoutCard(card, style: .compact) { viewModel.hangoutTapped(card.id) }
            }
        }
    }

    /// The Retry button on the error state.
    private func retry() { Task { await viewModel.reload() } }
}

/// Name, category, the closed status, address, hours and cost.
private struct SpotHeader: View {
    let content: SpotSheetContent

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: content.name)
                .font(Theme.Font.title2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: content.categoryText)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
            if content.isClosedByAuthorities {
                ClosedBadge()
            }
            Label(content.address, systemImage: "mappin.and.ellipse")
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textPrimary)
            FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
                InfoPill(icon: "clock", text: content.hoursText)
                InfoPill(icon: "indianrupeesign", text: content.costText)
            }
        }
    }
}

/// "Apple Maps details": looks the Place up by its Apple ID when tapped, then shows Apple's own place sheet (the one
/// allowed sheet on top of a sheet). MapKit may not be imported by ViewModels (ADR 006), and Apple's data may not be
/// stored (ARCHITECTURE 4), so the lookup lives here and runs only on tap, as in Apple's Landmarks sample.
private struct AppleDetailsButton: View {
    let applePlaceID: String
    @State private var mapItem: MKMapItem?
    @State private var isLooking = false
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            Button { Task { await lookUp() } } label: {
                Label(SpotSheetText.appleDetails, systemImage: "map")
                    .frame(minHeight: Theme.Size.minTapTarget)
            }
            .disabled(isLooking)
            if failed {
                Text(verbatim: SpotSheetText.appleDetailsFailed)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .mapItemDetailSheet(item: $mapItem)
    }

    private func lookUp() async {
        guard let identifier = MKMapItem.Identifier(rawValue: applePlaceID) else {
            failed = true
            return
        }
        isLooking = true
        defer { isLooking = false }
        do {
            mapItem = try await MKMapItemRequest(mapItemIdentifier: identifier).mapItem
            failed = false
        } catch {
            failed = true
        }
    }
}

/// The greyed-out shape of the sheet while it loads (`LoadStateView` redacts it).
private struct SpotPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Color.surfaceRaised)
                .aspectRatio(4 / 3, contentMode: .fit)
            Text(verbatim: "Spot name placeholder").font(Theme.Font.title2)
            Text(verbatim: "Category · address line placeholder").font(Theme.Font.subheadline)
            Text(verbatim: "Open until · cost").font(Theme.Font.subheadline)
            Spacer()
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
