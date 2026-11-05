import Components
import Design
import MapKit
import PhotosUI
import SwiftUI

/// Layout only: name, a map with a centre pin, category, note, the required photo, then Send. After sending: thanks.
struct SuggestPlaceView: View {
    @State private var viewModel: SuggestPlaceViewModel
    @State private var photoItem: PhotosPickerItem?
    @State private var camera: MapCameraPosition
    @ScaledMetric private var mapHeight: CGFloat = 220

    init(viewModel: SuggestPlaceViewModel) {
        _viewModel = State(initialValue: viewModel)
        let start = SuggestPlaceViewModel.startCentre
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude),
            latitudinalMeters: 1500, longitudinalMeters: 1500)))
    }

    var body: some View {
        Group {
            if viewModel.isSent { sent } else { form }
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.showsCancel && !viewModel.isSent {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SharedStrings.cancel) { viewModel.closeTapped() }
                }
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                await viewModel.photoPicked(data)
            }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                SafetyNote(viewModel.promise, style: .info)
                VybeTextField(verbatim: viewModel.nameLabel, text: $viewModel.name, errorText: viewModel.nameError)
                map
                Picker(viewModel.categoryLabel, selection: $viewModel.category) {
                    ForEach(viewModel.categories) { option in Text(verbatim: option.title).tag(option.category) }
                }
                .pickerStyle(.menu)
                .frame(minHeight: Theme.Size.minTapTarget)
                VybeTextField(verbatim: viewModel.noteLabel, text: $viewModel.note, errorText: viewModel.noteError)
                photoPicker
                if viewModel.hasFailed { SafetyNote(viewModel.errorMessage, style: .warning) }
            }
            .padding(Theme.Spacing.large)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(verbatim: viewModel.sendTitle, isLoading: viewModel.isSending) {
                Task { await viewModel.sendTapped() }
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)
            .background(.bar)
            .accessibilityIdentifier("editor.suggest.send")
        }
    }

    private var map: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            Map(position: $camera)
                .frame(height: mapHeight)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                .overlay {
                    Image(systemName: "mappin")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.critical)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    viewModel.mapMoved(latitude: context.region.center.latitude,
                                       longitude: context.region.center.longitude)
                }
                .accessibilityLabel(Text(verbatim: viewModel.mapHint))
            Text(verbatim: viewModel.mapHint).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private var photoPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                HStack(spacing: Theme.Spacing.medium) {
                    Image(systemName: "camera").foregroundStyle(Theme.Color.accent)
                    Text(verbatim: viewModel.photoLabel).font(Theme.Font.body).foregroundStyle(Theme.Color.textPrimary)
                    Spacer(minLength: Theme.Spacing.small)
                    if viewModel.photo != nil {
                        Label(viewModel.photoReady, systemImage: "checkmark.circle.fill")
                            .font(Theme.Font.footnote)
                            .foregroundStyle(Theme.Color.positive)
                    }
                }
                .padding(.horizontal, Theme.Spacing.medium)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
                .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            }
            if let missing = viewModel.photoMissing {
                Label(missing, systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.critical)
            }
            if viewModel.photoFailed { SafetyNote(viewModel.photoError, style: .warning) }
        }
    }

    private var sent: some View {
        VStack(spacing: Theme.Spacing.large) {
            Spacer(minLength: Theme.Spacing.large)
            Image(systemName: "checkmark.circle.fill")
                .font(Theme.Font.largeTitle)
                .foregroundStyle(Theme.Color.positive)
                .accessibilityHidden(true)
            Text(verbatim: viewModel.sentTitle)
                .font(Theme.Font.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: viewModel.sentBody)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: Theme.Spacing.large)
            PrimaryButton(verbatim: viewModel.doneTitle) { viewModel.closeTapped() }
        }
        .padding(Theme.Spacing.large)
        .vybeHaptic(.success, trigger: viewModel.isSent)
    }
}
