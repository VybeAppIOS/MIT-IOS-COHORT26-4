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
            .sheet(isPresented: $viewModel.isShowingFilters) { FiltersSheetView(viewModel: viewModel) }
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
                route(of: pin)
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

    /// One Hangout on the map: its Spots as numbered dots, joined by a line, so a multi-Spot Hangout never looks like
    /// a single place. Tapping any dot selects the whole Hangout.
    @MapContentBuilder
    private func route(of pin: DiscoverPin) -> some MapContent {
        let isSelected = viewModel.selectedHangoutID == pin.id
        if pin.route.count > 1 {
            MapPolyline(coordinates: pin.route.map(Self.location))
                .stroke(Theme.Color.accent.opacity(isSelected ? 1 : 0.75),
                        style: StrokeStyle(lineWidth: isSelected ? 5 : 3, lineCap: .round, lineJoin: .round))
        }
        ForEach(Array(pin.route.enumerated()), id: \.offset) { index, stop in
            Annotation(pin.title, coordinate: Self.location(stop), anchor: .center) {
                RouteSpotPin(title: pin.title, number: index + 1, total: pin.route.count, isPick: pin.isPick,
                             isSelected: isSelected)
            }
            .annotationTitles(.hidden)
            .tag(Self.tag(for: pin.id, spot: index))
        }
    }

    /// The first dot carries the plain Hangout ID; later dots add `#n` so every tag on the map is unique.
    private static func tag(for id: HangoutID, spot index: Int) -> String {
        index == 0 ? id.rawValue : "\(id.rawValue)#\(index)"
    }

    /// `Map(selection:)` speaks in tags; the ViewModel decides what a tag means (pin, cluster, or none). A `#n`
    /// suffix (a later Spot's dot) is dropped, so every dot of a Hangout selects that Hangout.
    private var selection: Binding<String?> {
        Binding(
            get: { viewModel.selectedHangoutID.map { Self.tag(for: $0, spot: 0) } },
            set: { viewModel.select(markerID: $0.map { String($0.split(separator: "#").first ?? "") }) })
    }

    // MARK: Overlays

    private var topBar: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.small) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.small) {
                        ForEach(DiscoverMapViewModel.Scope.allCases, id: \.self) { scope in
                            FilterChip(verbatim: scope.title, isSelected: viewModel.scope == scope) {
                                Task { await viewModel.scopeTapped(scope) }
                            }
                        }
                    }
                }
                filterButton
            }
            .padding(.horizontal, Theme.Spacing.large)
            .vybeAnimation(Theme.Motion.quick, value: viewModel.scope)
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

    /// The filters sheet opens from this icon. It fills with the accent colour while any filter is on.
    private var filterButton: some View {
        let isOn = viewModel.hasActiveFilters
        return Button { viewModel.moreFiltersTapped() } label: {
            Image(systemName: "slider.horizontal.3")
                .font(Theme.Font.subheadline)
                .foregroundStyle(isOn ? Theme.Color.onAccent : Theme.Color.textPrimary)
                .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                .background(isOn ? Theme.Color.accent : Theme.Color.surfaceRaised, in: Circle())
                .overlay { Circle().strokeBorder(isOn ? Color.clear : Theme.Color.separator) }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: DiscoverMapText.filtersLabel))
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("discover.map.filters")
    }

    /// The selected pin's preview card (SC-D2), or the Picks strip when nothing is selected.
    private var bottomBar: some View {
        VStack(spacing: 0) {
            if let card = viewModel.selectedCard {
                PinPreviewCard(
                    card: card, onOpen: { viewModel.cardTapped(card.id) },
                    onSave: { Task { await viewModel.saveTapped() } }, onDismiss: { viewModel.dismissPreview() })
                    .pinPreviewTransition()
            } else if case .loaded(let content, _) = viewModel.state, !content.picks.isEmpty {
                picksStrip(content.picks)
            }
        }
        .vybeAnimation(Theme.Motion.standard, value: viewModel.selectedHangoutID)   // slides up (MOTION 1)
        .vybeHaptic(.selection, trigger: viewModel.selectedHangoutID)
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
                            // The featured card is a 4:3 photo, so its width sets its height: about 62% of the
                            // screen keeps the strip short, the map in view and the next card peeking in.
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.62 }
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
            Text(verbatim: viewModel.emptyMessage)
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
