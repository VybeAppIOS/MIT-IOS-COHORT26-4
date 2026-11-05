import Components
import Design
import MapKit
import Models
import SwiftUI

/// Layout only: every value comes from `LiveViewModel`, every tap goes to it. The one exception is the walking route
/// line, which needs MapKit (not allowed in ViewModels): it is asked for once when the screen opens.
struct LiveView: View {
    @State private var viewModel: LiveViewModel
    @State private var hasAppeared = false
    @Environment(\.dynamicTypeSize) private var typeSize

    init(viewModel: LiveViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            if !typeSize.isAccessibilitySize, !viewModel.spots.isEmpty {
                LiveMap(spots: viewModel.spots, currentID: viewModel.currentSpot?.id)
                    .frame(maxHeight: .infinity)
            }
            currentSpotCard
            if !typeSize.isAccessibilitySize {
                nextSpots.frame(maxHeight: .infinity)
            } else {
                nextSpots                   // at the largest sizes only this part scrolls
            }
        }
        .safeAreaInset(edge: .bottom) { mainButton }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.hangoutTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .confirmationDialog(LiveText.endConfirmTitle, isPresented: $viewModel.isConfirmingEnd,
                            titleVisibility: .visible) {
            Button(LiveText.end, role: .destructive) { viewModel.endConfirmed() }
            Button(LiveText.keepGoing, role: .cancel) {}
        } message: {
            Text(verbatim: LiveText.endConfirmMessage)
        }
        .sheet(isPresented: $viewModel.isShowingMarkVisited) {
            if let markVisited = viewModel.markVisited { MarkVisitedView(viewModel: markVisited) }
        }
        .vybeHaptic(.start, trigger: hasAppeared)          // MOTION moment 4
        .vybeHaptic(.stop, trigger: viewModel.endCount)
        .task { await viewModel.load() }
        .task { await viewModel.followLocation() }
        .onAppear { hasAppeared = true }
    }

    // MARK: The current Spot (big, glanceable)

    private var currentSpotCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                Text(verbatim: viewModel.progressText)
                Spacer()
                if let startedAt = viewModel.startedAt {
                    Text(startedAt, style: .timer)
                        .monospacedDigit()
                }
            }
            .font(Theme.Font.subheadline)
            .foregroundStyle(Theme.Color.textSecondary)
            if let current = viewModel.currentSpot {
                Text(verbatim: LiveText.nowHeading)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.accent)
                Text(verbatim: current.place.name)
                    .font(Theme.Font.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let distance = viewModel.distanceText {
                    Text(verbatim: distance)
                        .font(Theme.Font.title3)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .contentTransition(.numericText())
                }
            } else if !viewModel.spots.isEmpty {
                Text(verbatim: LiveText.allVisited)
                    .font(Theme.Font.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Color.textPrimary)
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.surfaceRaised)
    }

    private var nextSpots: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Text(verbatim: LiveText.spotsHeader)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(viewModel.rows) { row in SpotRow(row) }
            }
            .padding(Theme.Spacing.large)
        }
    }

    private var mainButton: some View {
        Group {
            if viewModel.currentSpot != nil {
                PrimaryButton(verbatim: LiveText.markVisited) { viewModel.markVisitedTapped() }
                    .accessibilityIdentifier("live.markVisited")
            } else {
                PrimaryButton(verbatim: LiveText.end) { viewModel.endTapped() }
                    .accessibilityIdentifier("live.endPrimary")
            }
        }
        .padding(Theme.Spacing.large)
        .background(.bar)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { viewModel.minimiseTapped() } label: {
                Label(LiveText.minimise, systemImage: "chevron.down")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(LiveText.end, role: .destructive) { viewModel.endTapped() }
        }
    }
}

/// The map: the Spots, the person, and the walking route between the Spots. The route is asked from Apple once when
/// the screen opens and kept; if that fails or is throttled, straight lines between the Spots are drawn instead.
private struct LiveMap: View {
    let spots: [LiveSpot]
    let currentID: SpotID?
    @State private var walkingLines: [MKPolyline]?

    var body: some View {
        Map(initialPosition: .automatic) {
            if let walkingLines {
                ForEach(walkingLines.indices, id: \.self) { index in
                    MapPolyline(walkingLines[index]).stroke(Theme.Color.accent, lineWidth: 5)
                }
            } else {
                MapPolyline(coordinates: spots.map { Self.location($0.place.coordinate) })
                    .stroke(Theme.Color.accent.opacity(0.6), style: StrokeStyle(lineWidth: 4, dash: [8, 6]))
            }
            ForEach(spots) { item in
                Marker(item.place.name, coordinate: Self.location(item.place.coordinate))
                    .tint(item.id == currentID ? Theme.Color.accent : Theme.Color.textSecondary)
            }
            UserAnnotation()
        }
        .mapControls { MapUserLocationButton() }
        .task { await requestWalkingRoute() }
    }

    /// One `MKDirections` walking request per leg, once. Any failure keeps the straight-line fallback.
    private func requestWalkingRoute() async {
        guard walkingLines == nil, spots.count > 1 else { return }
        var lines: [MKPolyline] = []
        for (start, end) in zip(spots, spots.dropFirst()) {
            let request = MKDirections.Request()
            request.source = MKMapItem(location: Self.clLocation(start.place.coordinate), address: nil)
            request.destination = MKMapItem(location: Self.clLocation(end.place.coordinate), address: nil)
            request.transportType = .walking
            guard let route = try? await MKDirections(request: request).calculate().routes.first else { return }
            lines.append(route.polyline)
        }
        walkingLines = lines
    }

    private static func location(_ coordinate: Coordinate) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    private static func clLocation(_ coordinate: Coordinate) -> CLLocation {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
