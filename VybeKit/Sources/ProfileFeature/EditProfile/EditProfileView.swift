import Components
import Design
import PhotosUI
import SwiftUI

/// Layout only: a sheet with its own navigation bar (Cancel), the fields with inline errors, and Save at the bottom.
struct EditProfileView: View {
    @State private var viewModel: EditProfileViewModel
    @State private var photoItem: PhotosPickerItem?
    @State private var bannerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    init(viewModel: EditProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    pictures
                    VybeTextField(verbatim: viewModel.nameLabel, text: $viewModel.name,
                                  errorText: viewModel.nameError)
                        .textContentType(.name)
                        .submitLabel(.next)
                    usernameField
                    bioField
                    interestsField
                    if viewModel.hasFailed { SafetyNote(viewModel.errorMessage, style: .warning) }
                }
                .padding(Theme.Spacing.large)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.Color.surface)
            .navigationTitle(Text(verbatim: viewModel.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SharedStrings.cancel) { if viewModel.closeTapped() { dismiss() } }
                }
            }
            .safeAreaInset(edge: .bottom) { saveBar }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.hasChanges)
        .confirmationDialog(viewModel.discardConfirm, isPresented: $viewModel.isConfirmingDiscard,
                            titleVisibility: .visible) {
            Button(viewModel.discardTitle, role: .destructive) { dismiss() }
            Button(viewModel.keepEditing, role: .cancel) {}
        }
        .onChange(of: viewModel.isSaved) { _, saved in if saved { dismiss() } }
        .onChange(of: photoItem) { _, item in load(item, isBanner: false) }
        .onChange(of: bannerItem) { _, item in load(item, isBanner: true) }
        .hidesTabBar()
    }

    private var pictures: some View {
        // Read from the view model here: the picker builds its label off the main actor.
        let photo = PickerLabel(title: viewModel.photoLabel, systemImage: "person.crop.circle",
                                readyText: viewModel.newPhoto != nil ? viewModel.photoReady : nil)
        let banner = PickerLabel(title: viewModel.bannerLabel, systemImage: "photo",
                                 readyText: viewModel.newBanner != nil ? viewModel.photoReady : nil)
        return VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            PhotosPicker(selection: $photoItem, matching: .images) { photo }
            PhotosPicker(selection: $bannerItem, matching: .images) { banner }
            if viewModel.photoFailed { SafetyNote(viewModel.photoError, style: .warning) }
        }
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            VybeTextField(verbatim: viewModel.usernameLabel, text: $viewModel.username,
                          errorText: viewModel.usernameError)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.username)
                .onChange(of: viewModel.username) { _, _ in viewModel.usernameEdited() }
            if let hold = viewModel.usernameHoldNote {
                Text(verbatim: hold).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }

    private var bioField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            Text(verbatim: viewModel.bioLabel).font(Theme.Font.subheadline).foregroundStyle(Theme.Color.textSecondary)
            TextField(viewModel.bioLabel, text: $viewModel.bio, axis: .vertical)
                .font(Theme.Font.body)
                .lineLimit(3...6)
                .padding(Theme.Spacing.medium)
                .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            HStack {
                if let error = viewModel.bioError {
                    Text(verbatim: error).foregroundStyle(Theme.Color.critical)
                }
                Spacer(minLength: 0)
                Text(verbatim: viewModel.bioCountText)
                    .foregroundStyle(viewModel.bioError == nil ? Theme.Color.textSecondary : Theme.Color.critical)
            }
            .font(Theme.Font.caption)
        }
    }

    private var interestsField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(verbatim: viewModel.interestsLabel)
            FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
                ForEach(viewModel.interestOptions) { option in
                    FilterChip(verbatim: option.title, isSelected: viewModel.isSelected(option)) {
                        viewModel.toggleInterest(option)
                    }
                }
            }
            Text(verbatim: viewModel.interestsError ?? viewModel.interestsCountText)
                .font(Theme.Font.caption)
                .foregroundStyle(viewModel.interestsError == nil ? Theme.Color.textSecondary : Theme.Color.critical)
        }
    }

    private var saveBar: some View {
        PrimaryButton(verbatim: viewModel.saveTitle, isLoading: viewModel.isSaving) {
            Task { await viewModel.save() }
        }
        .disabled(!viewModel.canSave)
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(.bar)
        .accessibilityIdentifier("profile.edit.save")
    }

    private func load(_ item: PhotosPickerItem?, isBanner: Bool) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            await viewModel.photoPicked(data, isBanner: isBanner)
        }
    }
}

/// The row inside a photo picker: plain values, because the picker builds its label off the main actor.
private struct PickerLabel: View {
    let title: String
    let systemImage: String
    /// Set once a picture has been chosen, for example "Ready".
    let readyText: String?

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: systemImage).foregroundStyle(Theme.Color.accent)
            Text(verbatim: title).font(Theme.Font.body).foregroundStyle(Theme.Color.textPrimary)
            Spacer(minLength: Theme.Spacing.small)
            if let readyText {
                Label(readyText, systemImage: "checkmark.circle.fill")
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.positive)
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
        .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }
}
