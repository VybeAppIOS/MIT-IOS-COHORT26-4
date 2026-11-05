import Components
import Design
import SwiftUI

/// Layout only: the header, the three library rows, then my posts (or an empty note). Settings is the gear.
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func editingEnded() { Task { await viewModel.editingEnded() } }
    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { content in
            ScrollView {
                page(content)
            }
        } placeholder: {
            ScrollView {
                page(ProfileContent(header: ProfileHeaderData(name: "Sample Name", username: "@sample.name"),
                                    posts: []))
            }
        } empty: {
            EmptyStateView(systemImage: "person.crop.circle", message: viewModel.emptyPosts)
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                IconButton(systemImage: "gearshape", verbatimLabel: viewModel.settingsLabel) {
                    viewModel.settingsTapped()
                }
                .accessibilityIdentifier("profile.profile.settings")
            }
        }
        .sheet(item: $viewModel.editing, onDismiss: editingEnded) { profile in
            EditProfileView(viewModel: viewModel.makeEditViewModel(profile))
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }

    private func page(_ content: ProfileContent) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            ProfileHeader(content.header, relationship: .own) { viewModel.editTapped() }
            libraryRows.padding(.horizontal, Theme.Spacing.large)
            SectionHeader(verbatim: viewModel.postsHeader).padding(.horizontal, Theme.Spacing.large)
            if content.posts.isEmpty {
                EmptyStateView(systemImage: "map", message: viewModel.emptyPosts)
            } else {
                LazyVStack(spacing: Theme.Spacing.extraLarge) {
                    ForEach(content.posts) { post in
                        PostCard(post, actions: PostCardActions(open: { viewModel.postTapped(post.id) },
                                                                comment: { viewModel.postTapped(post.id) }))
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
            }
        }
        .padding(.bottom, Theme.Spacing.extraLarge)
    }

    private var libraryRows: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.libraryRows) { row in
                NavRow(verbatim: row.title, subtitle: row.hint, value: row.count.formatted(),
                       systemImage: row.systemImage) {
                    viewModel.libraryRowTapped(row)
                }
                .padding(.horizontal, Theme.Spacing.large)
                .accessibilityIdentifier("profile.profile.\(row.id)")
                if row.id != viewModel.libraryRows.last?.id {
                    Divider().padding(.leading, Theme.Spacing.large)
                }
            }
        }
        .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.large))
    }
}
