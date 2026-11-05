import Components
import Design
import MapKit
import Models
import SwiftUI

/// Layout only: every value comes from `DiscoverMapViewModel`, every tap goes to it. This View owns the map camera
/// (MapKit types never reach the ViewModel, ADR 006): it reports the visible span and zooms to a tapped cluster.
struct DiscoverMapView: View {
    @State private var viewModel: DiscoverMapViewModel
    /// Starts by framing every pin, so the map works with location denied and needs no fixed start point.
    @State private var position: MapCameraPosition = .automatic

    init(viewModel: DiscoverMapViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        map
            .safeAreaInset(edge: .top) { topBar }
            .safeAreaInset(edge: .bottom) { bottomBar }    // keeps Apple's logo and Legal link above our views
            .overlay { statusOverlay }
            .sheet(isPresented: $viewModel.isShowingFilters) { FiltersPlaceholder() }
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.load() }
            .onChange(of: viewModel.zoomRequest) { _, cluster in
                guard let cluster else { return }
                position = .region(Self.region(around: cluster))
                viewModel.zoomHandled()
            }
    }

    // MARK: The map

    private var map: some View {
        Map(position: $position, selection: selection) {
            ForEach(viewModel.visiblePins) { pin in
                Annotation(pin.title, coordinate: Self.location(pin.coordinate), anchor: .bottom) {
                    HangoutPin(title: pin.title, category: pin.category, photoURL: pin.photoURL, isPick: pin.isPick,
                               isSelected: viewModel.selectedHangoutID == pin.id)
                }
                .annotationTitles(.hidden)
                .tag(pin.id.rawValue)
            }
            ForEach(viewModel.visibleClusters) { cluster in
                Annotation(ComponentStrings.clusterLabel(cluster.ids.count),
                           coordinate: Self.location(cluster.center)) {
                    ClusterPin(count: cluster.ids.count)
                }
                .annotationTitles(.hidden)
                .tag(cluster.id)
            }
            UserAnnotation()
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()     // does nothing until location is allowed; the map works without it
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.cameraChanged(latitudeSpan: context.region.span.latitudeDelta,
                                    longitudeSpan: context.region.span.longitudeDelta)
        }
        .vybeAnimation(Theme.Motion.quick, value: viewModel.markers)   // pins fade, never fly (MOTION 3)
    }

    /// `Map(selection:)` speaks in tags; the ViewModel decides what a tag means (pin, cluster, or none).
    private var selection: Binding<String?> {
        Binding(get: { viewModel.selectedHangoutID?.rawValue }, set: { viewModel.select(markerID: $0) })
    }

    // MARK: Overlays

    private var topBar: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.small) {
                    ForEach(DiscoverMapViewModel.Chip.allCases, id: \.self) { chip in
                        FilterChip(verbatim: chip.title, isSelected: viewModel.selectedChips.contains(chip)) {
                            Task { await viewModel.chipTapped(chip) }
                        }
                    }
                    Button { viewModel.moreFiltersTapped() } label: {
                        Label(DiscoverMapText.moreFilters, systemImage: "slider.horizontal.3")
                            .font(Theme.Font.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .frame(minHeight: Theme.Size.minTapTarget)
                }
                .padding(.horizontal, Theme.Spacing.large)
            }
            .vybeAnimation(Theme.Motion.quick, value: viewModel.selectedChips)
            if viewModel.showsOfflineBanner {
                OfflineBanner()
            }
            if viewModel.showsMonsoonNote {
                SafetyNote(DiscoverMapText.monsoon, style: .warning)
                    .padding(.horizontal, Theme.Spacing.large)
            }
        }
        .padding(.vertical, Theme.Spacing.small)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if let card = viewModel.selectedCard {
            // SC-D1's plain card for the selected pin; SC-D2 replaces it with the full preview card.
            HangoutCard(card, style: .compact) { viewModel.cardTapped(card.id) }
                .vybeZoomSource(id: card.id)
                .padding(Theme.Spacing.large)
        } else if case .loaded(let content, _) = viewModel.state, !content.picks.isEmpty {
            picksStrip(content.picks)
        }
    }

    private func picksStrip(_ picks: [HangoutCardData]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: DiscoverMapText.picksHeader)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, Theme.Spacing.large)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Theme.Spacing.medium) {
                    ForEach(picks) { card in
                        HangoutCard(card, style: .featured) { viewModel.cardTapped(card.id) }
                            .vybeZoomSource(id: card.id)
                            // The featured card is a 4:5 photo, so its width sets its height: about 42% of the
                            // screen keeps the strip to roughly a third of it and the map in view.
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.42 }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, Theme.Spacing.large, for: .scrollContent)
            .fixedSize(horizontal: false, vertical: true)   // a horizontal ScrollView would fill all the height
                                                            // it is offered; keep it to the cards' own height
        }
        .padding(.vertical, Theme.Spacing.medium)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var statusOverlay: some View {
        if case .loading = viewModel.state {
            ProgressView()
                .padding(Theme.Spacing.large)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        } else if case .failed(let error) = viewModel.state {
            ErrorView(error, onRetry: retry)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.large))
                .padding(Theme.Spacing.large)
        } else if viewModel.showsEmptyMessage {
            Text(verbatim: DiscoverMapText.empty)
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(Theme.Spacing.large)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
                .padding(Theme.Spacing.large)
        }
    }

    /// The Retry button on the error card.
    private func retry() { Task { await viewModel.reload() } }

    // MARK: Converting between our Coordinate and MapKit

    private static func location(_ coordinate: Coordinate) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    /// Twice the cluster's own size (at least about 200 m), so its Hangouts separate after the zoom.
    private static func region(around cluster: PinCluster) -> MKCoordinateRegion {
        let minimum = 0.002
        return MKCoordinateRegion(
            center: location(cluster.center),
            span: MKCoordinateSpan(latitudeDelta: max(minimum, (cluster.maxLatitude - cluster.minLatitude) * 2),
                                   longitudeDelta: max(minimum, (cluster.maxLongitude - cluster.minLongitude) * 2)))
    }
}

/// Stands in for the filters sheet until SC-D3 replaces it. Developer-only text, so it is not localized.
private struct FiltersPlaceholder: View {
    var body: some View {
        Text(verbatim: "Filters: SC-D3")
            .font(Theme.Font.headline)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }
}
