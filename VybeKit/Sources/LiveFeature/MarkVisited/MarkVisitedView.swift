import Design
import PhotosUI
import SwiftUI
import UIKit

/// The Mark visited sheet (H2), the app's hero moment (MOTION moment 5). Layout only: every value comes from
/// `MarkVisitedViewModel`; picking a photo turns it into bytes here because PhotosUI belongs to the View layer.
struct MarkVisitedView: View {
    @State private var viewModel: MarkVisitedViewModel
    @State private var pickedItem: PhotosPickerItem?
    @State private var showsPicker = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.vybeReduceMotionOverride) private var reduceMotionOverride   // previews only
    @ScaledMetric(relativeTo: .body) private var thumbnailSize = 64.0

    init(viewModel: MarkVisitedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            mark
            Text(verbatim: title)
                .font(Theme.Font.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            if !viewModel.isDone {
                photos
                PrimaryButton(verbatim: MarkVisitedText.done) { Task { await viewModel.doneTapped() } }
                    .accessibilityIdentifier("live.markVisited.done")
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity)
        .overlay {
            if viewModel.showsConfetti(reduceMotion: reduceMotion) {
                Confetti().allowsHitTesting(false).accessibilityHidden(true)
            }
        }
        .vybeAnimation(reduceMotion ? Theme.Motion.fade : Theme.Motion.playful, value: viewModel.isDone)
        .vybeHaptic(.success, trigger: viewModel.isDone)
        .presentationDetents([.height(340), .medium])
        .presentationDragIndicator(.visible)
        .photosPicker(isPresented: $showsPicker, selection: $pickedItem, matching: .images, photoLibrary: .shared())
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.photoPicked(data)
                } else {
                    viewModel.photoLoadFailed()
                }
                pickedItem = nil
            }
        }
    }

    private var title: String {
        guard viewModel.isDone else { return MarkVisitedText.question(viewModel.spotName) }
        return viewModel.isLastSpot ? MarkVisitedText.allVisited : MarkVisitedText.visited
    }

    /// Circle → checkmark. Normally an SF Symbol replace with a bounce; with Reduce Motion a plain fade, and the
    /// checkmark plus the text still say it is done.
    private var mark: some View {
        Group {
            if reduceMotion {
                ZStack {
                    Image(systemName: "circle").opacity(viewModel.isDone ? 0 : 1)
                    Image(systemName: "checkmark.circle.fill").opacity(viewModel.isDone ? 1 : 0)
                }
            } else {
                Image(systemName: viewModel.isDone ? "checkmark.circle.fill" : "circle")
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: viewModel.isDone)
            }
        }
        .font(Theme.Font.largeTitle)
        .imageScale(.large)
        .foregroundStyle(viewModel.isDone ? Theme.Color.positive : Theme.Color.textSecondary)
        .accessibilityHidden(true)
    }

    private var photos: some View {
        VStack(spacing: Theme.Spacing.small) {
            if !viewModel.pickedPhotos.isEmpty {
                HStack(spacing: Theme.Spacing.small) {
                    ForEach(viewModel.pickedPhotos.indices, id: \.self) { index in
                        thumbnail(index)
                    }
                }
            }
            if viewModel.photosLeft > 0 {
                Button { showsPicker = true } label: {
                    Label(MarkVisitedText.addPhoto, systemImage: "camera")
                        .font(Theme.Font.headline)
                        .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
                }
                .buttonStyle(.bordered)
                .tint(Theme.Color.accent)
                .disabled(!viewModel.canAddPhoto)
                .overlay { if viewModel.isProcessing { ProgressView() } }
            } else {
                Text(verbatim: MarkVisitedText.limitReached(viewModel.photoLimit))
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            if let error = viewModel.photoError {
                Text(verbatim: error)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.critical)
            }
        }
    }

    private func thumbnail(_ index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            if let image = UIImage(data: viewModel.pickedPhotos[index].thumbnail) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: thumbnailSize, height: thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
            }
            Button { viewModel.removePhoto(at: index) } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Theme.Color.onAccent, Theme.Color.scrim)
            }
            .accessibilityLabel(Text(verbatim: MarkVisitedText.removePhoto))
        }
    }
}

/// A one-time burst of confetti for the last Spot (simple shapes, no library). Never shown with Reduce Motion.
private struct Confetti: View {
    @State private var falling = false
    private let colors = [Theme.Color.accent, Theme.Color.positive, Theme.Color.warning, Theme.Color.critical]

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<24, id: \.self) { index in
                RoundedRectangle(cornerRadius: Theme.Radius.small / 4)
                    .fill(colors[index % colors.count])
                    .frame(width: Theme.Spacing.small, height: Theme.Spacing.medium)
                    .rotationEffect(.degrees(falling ? Double(index * 47) : 0))
                    .position(x: proxy.size.width * (Double(index % 8) + 0.5) / 8,
                              y: falling ? proxy.size.height + 20 : -20 - Double(index / 8) * 24)
                    .opacity(falling ? 0 : 1)
            }
        }
        .onAppear { withAnimation(Theme.Motion.gentle.speed(0.4)) { falling = true } }
    }
}
