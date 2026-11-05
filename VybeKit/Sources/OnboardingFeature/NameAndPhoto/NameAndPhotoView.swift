import Design
import PhotosUI
import SwiftUI
import UIKit

/// Layout only: every value comes from `NameAndPhotoViewModel`, every tap goes to it. The one job done here is
/// turning the picked item into bytes, because PhotosUI belongs to the View layer (ADR 006).
struct NameAndPhotoView: View {
    @State private var viewModel: NameAndPhotoViewModel
    @State private var pickedItem: PhotosPickerItem?
    @State private var showsPicker = false
    @ScaledMetric(relativeTo: .largeTitle) private var circleSize = 120.0

    init(viewModel: NameAndPhotoViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.extraLarge) {
                Text(verbatim: NameAndPhotoText.title)
                    .font(Theme.Font.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                photoSection
                nameSection
            }
            .padding(Theme.Spacing.large)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(verbatim: NameAndPhotoText.continueButton) { viewModel.continueTapped() }
                .disabled(!viewModel.canContinue)
                .padding(Theme.Spacing.large)
                .accessibilityIdentifier("onboarding.nameAndPhoto.continue")
        }
        .background(Theme.Color.surface)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.photoPicked(data)
                } else {
                    viewModel.photoLoadFailed()
                }
                pickedItem = nil                    // so the same photo can be picked again
            }
        }
    }

    // MARK: Photo

    private var photoSection: some View {
        VStack(spacing: Theme.Spacing.small) {
            // A plain Button plus `.photosPicker`: PhotosPicker's own label closure is @Sendable and could not
            // read this main-actor view's properties.
            Button { showsPicker = true } label: { photoCircle }
            .buttonStyle(.plain)
            .photosPicker(isPresented: $showsPicker, selection: $pickedItem, matching: .images,
                          photoLibrary: .shared())
            .accessibilityLabel(Text(verbatim: viewModel.photoPreview == nil
                                     ? NameAndPhotoText.addPhoto : NameAndPhotoText.changePhoto))
            .accessibilityIdentifier("onboarding.nameAndPhoto.photo")
            if viewModel.photoPreview != nil {
                Button(NameAndPhotoText.removePhoto, role: .destructive) { viewModel.removePhoto() }
                    .font(Theme.Font.subheadline)
                    .frame(minHeight: Theme.Size.minTapTarget)
            } else {
                Text(verbatim: NameAndPhotoText.photoOptional)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            if let photoError = viewModel.photoError {
                Text(verbatim: photoError)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.critical)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var photoCircle: some View {
        ZStack {
            Circle().fill(Theme.Color.surfaceRaised)
            if let data = viewModel.photoPreview, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(Theme.Font.largeTitle)
                    .foregroundStyle(Theme.Color.accent)
            }
            if viewModel.isProcessingPhoto {
                ProgressView()
                    .accessibilityLabel(Text(verbatim: NameAndPhotoText.processing))
            }
        }
        .frame(width: circleSize, height: circleSize)
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.Color.separator))
    }

    // MARK: Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            TextField(NameAndPhotoText.namePlaceholder, text: $viewModel.name)
                .font(Theme.Font.body)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .submitLabel(.continue)
                .onSubmit { viewModel.continueTapped() }
                .padding(Theme.Spacing.medium)
                .frame(minHeight: Theme.Size.minTapTarget)
                .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
                .accessibilityIdentifier("onboarding.nameAndPhoto.name")
            if let error = viewModel.nameError {
                Text(verbatim: error)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.critical)
                    .accessibilityIdentifier("onboarding.nameAndPhoto.nameError")
            }
        }
    }
}
