import Components
import Design
import SwiftUI

/// Layout only: the Edit post sheet. Words, photos, tags, audience; the Spots read-only; Delete post at the bottom.
struct EditPostView: View {
    @State private var viewModel: EditPostViewModel

    init(viewModel: EditPostViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { _ in
            form
        } placeholder: {
            List { Text(verbatim: viewModel.screenTitle) }
        } empty: {
            EmptyView()
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.screenTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(SharedStrings.cancel) { viewModel.cancelTapped() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(viewModel.saveTitle) { Task { await viewModel.saveTapped() } }
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("posting.edit.save")
            }
        }
        .confirmationDialog(viewModel.publicConfirmTitle, isPresented: $viewModel.isConfirmingPublic,
                            titleVisibility: .visible) {
            Button(viewModel.publicConfirmButton) { viewModel.publicConfirmed() }
            Button(SharedStrings.cancel, role: .cancel) {}
        } message: {
            Text(verbatim: viewModel.publicWarning)
        }
        .confirmationDialog(viewModel.deleteConfirmTitle, isPresented: $viewModel.isConfirmingDelete,
                            titleVisibility: .visible) {
            Button(viewModel.deleteTitle, role: .destructive) { Task { await viewModel.deleteConfirmed() } }
            Button(SharedStrings.cancel, role: .cancel) {}
        } message: {
            Text(verbatim: viewModel.deleteConfirmMessage)
        }
        .task { await viewModel.load() }
        .hidesTabBar()
    }

    private var form: some View {
        List {
            Section {
                VybeTextField(verbatim: String(localized: "posting.field.title", bundle: #bundle),
                              text: $viewModel.title, errorText: viewModel.titleError)
                VybeTextField(verbatim: String(localized: "posting.field.caption", bundle: #bundle),
                              text: $viewModel.caption, errorText: viewModel.captionError)
            }
            Section(String(localized: "posting.section.photos", bundle: #bundle)) {
                ForEach(viewModel.photoRows) { row in
                    Button { viewModel.coverTapped(row.id) } label: { EditPostPhotoLine(row: row) }
                        .swipeActions {
                            Button(String(localized: "posting.photo.remove", bundle: #bundle), role: .destructive) {
                                viewModel.removePhoto(row.id)
                            }
                        }
                }
                .onMove { viewModel.movePhotos(from: $0, to: $1) }
            }
            Section(String(localized: "posting.section.tags", bundle: #bundle)) {
                FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
                    ForEach(viewModel.tagOptions) { option in
                        FilterChip(verbatim: option.title, isSelected: viewModel.tags.contains(option.value)) {
                            viewModel.toggleTag(option.value)
                        }
                    }
                }
            }
            Section(String(localized: "posting.section.audience", bundle: #bundle)) {
                ForEach(viewModel.audienceOptions) { option in
                    Button { viewModel.audienceTapped(option.value) } label: {
                        EditPostChoiceLine(title: option.title, isSelected: viewModel.visibility == option.value)
                    }
                }
                if let note = viewModel.privateNote { SafetyNote(note, style: .info) }
            }
            Section {
                ForEach(viewModel.spotRows) { row in
                    Text(verbatim: row.text).font(Theme.Font.body).foregroundStyle(Theme.Color.textSecondary)
                }
            } header: {
                Text("posting.section.spots", bundle: #bundle)
            } footer: {
                Text(verbatim: viewModel.spotsLocked)
            }
            Section {
                Button(viewModel.deleteTitle, role: .destructive) { viewModel.deleteTapped() }
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .accessibilityIdentifier("posting.edit.delete")
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct EditPostPhotoLine: View {
    let row: ComposerPhotoRow
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
        }
        .frame(minHeight: Theme.Size.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A row with a checkmark when chosen (the checkmark, not colour alone, shows the state).
private struct EditPostChoiceLine: View {
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
