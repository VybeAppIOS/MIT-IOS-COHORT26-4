import Components
import Design
import SwiftUI

/// Layout only: preview card, title and caption, photos, tags, audience and when; Post sits in the bottom bar.
struct ComposerView: View {
    @State private var viewModel: ComposerViewModel

    init(viewModel: ComposerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: { Task { await viewModel.reload() } }) { _ in
            form
        } placeholder: {
            List { Text(verbatim: viewModel.screenTitle) }
        } empty: {
            EmptyView()
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.screenTitle))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(viewModel.publicConfirmTitle, isPresented: $viewModel.isConfirmingPublic,
                            titleVisibility: .visible) {
            Button(viewModel.publicConfirmButton) { viewModel.publicConfirmed() }
            Button(SharedStrings.cancel, role: .cancel) {}
        } message: {
            Text(verbatim: viewModel.publicWarning)
        }
        .task { await viewModel.load() }
    }

    private var form: some View {
        List {
            if let card = viewModel.previewCard {
                Section(String(localized: "posting.section.preview", bundle: #bundle)) {
                    PostCard(card, actions: PostCardActions(open: {}))
                        .allowsHitTesting(false)
                        .listRowInsets(EdgeInsets())
                }
            }
            Section {
                VybeTextField(verbatim: String(localized: "posting.field.title", bundle: #bundle),
                              text: $viewModel.title, errorText: viewModel.titleError)
                VybeTextField(verbatim: String(localized: "posting.field.caption", bundle: #bundle),
                              text: $viewModel.caption, errorText: viewModel.captionError)
                Text(verbatim: viewModel.captionCountText)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            ComposerPhotosSection(viewModel: viewModel)
            ComposerChoicesSection(viewModel: viewModel)
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { postBar }
    }

    private var postBar: some View {
        VStack(spacing: Theme.Spacing.small) {
            PrimaryButton(verbatim: viewModel.postTitle, isLoading: viewModel.isPosting) {
                Task { await viewModel.postTapped() }
            }
            .disabled(!viewModel.canPost)
            .accessibilityIdentifier("posting.composer.post")
            if let reason = viewModel.postBlockedReason {
                Text(verbatim: reason)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(.bar)
    }
}

/// The photos in the post (drag to reorder, swipe to set aside, tap to make the cover) and the ones set aside.
private struct ComposerPhotosSection: View {
    @Bindable var viewModel: ComposerViewModel

    var body: some View {
        Section {
            ForEach(viewModel.includedRows) { row in
                Button { viewModel.coverTapped(row.id) } label: { ComposerPhotoLine(row: row, systemImage: nil) }
                    .swipeActions {
                        Button(String(localized: "posting.photo.remove", bundle: #bundle), role: .destructive) {
                            viewModel.removePhoto(row.id)
                        }
                    }
            }
            .onMove { viewModel.movePhotos(from: $0, to: $1) }
            ForEach(viewModel.setAsideRows) { row in
                Button { viewModel.addBackPhoto(row.id) } label: {
                    ComposerPhotoLine(row: row, systemImage: "plus.circle")
                }
                .disabled(!viewModel.canAddPhoto)
            }
        } header: {
            Text(verbatim: viewModel.photoCountText)
        } footer: {
            Text("posting.photos.footer", bundle: #bundle)
        }
    }
}

private struct ComposerPhotoLine: View {
    let row: ComposerPhotoRow
    /// Shown for a set-aside photo ("add back").
    let systemImage: String?
    @ScaledMetric private var thumbWidth: CGFloat = 64

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            PlaceImage(url: row.url, aspectRatio: 4.0 / 3.0)
                .frame(width: thumbWidth)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                .accessibilityHidden(true)
            Text(verbatim: row.label).font(Theme.Font.body).foregroundStyle(Theme.Color.textPrimary)
            Spacer(minLength: Theme.Spacing.small)
            if row.isCover {
                Text("posting.photo.cover", bundle: #bundle)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.accent)
            }
            if let systemImage {
                Image(systemName: systemImage).foregroundStyle(Theme.Color.accent).accessibilityHidden(true)
            }
        }
        .frame(minHeight: Theme.Size.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Tags, audience and when.
private struct ComposerChoicesSection: View {
    @Bindable var viewModel: ComposerViewModel

    var body: some View {
        Section(String(localized: "posting.section.tags", bundle: #bundle)) {
            FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
                ForEach(viewModel.tagOptions) { option in
                    FilterChip(verbatim: option.title, isSelected: viewModel.tags.contains(option.value)) {
                        viewModel.toggleTag(option.value)
                    }
                }
            }
        }
        Section {
            ForEach(viewModel.audienceOptions) { option in
                Button { viewModel.audienceTapped(option.value) } label: {
                    ChoiceLine(title: option.title, isSelected: viewModel.visibility == option.value)
                }
            }
            if let note = viewModel.privateNote { SafetyNote(note, style: .info) }
        } header: {
            Text("posting.section.audience", bundle: #bundle)
        }
        Section(String(localized: "posting.section.when", bundle: #bundle)) {
            ForEach(viewModel.delayOptions) { option in
                Button { viewModel.delay = option.value } label: {
                    ChoiceLine(title: option.title, isSelected: viewModel.delay == option.value)
                }
            }
        }
    }
}

/// A row with a checkmark when chosen (the checkmark, not colour alone, shows the state).
private struct ChoiceLine: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(verbatim: title).font(Theme.Font.body).foregroundStyle(Theme.Color.textPrimary)
            Spacer(minLength: Theme.Spacing.small)
            if isSelected { Image(systemName: "checkmark").foregroundStyle(Theme.Color.accent) }
        }
        .frame(minHeight: Theme.Size.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
