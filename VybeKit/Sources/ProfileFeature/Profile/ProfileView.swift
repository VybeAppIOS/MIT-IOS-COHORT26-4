import Components
import Design
import SwiftUI

/// Layout only: the header, the three library rows, then my posts (or an empty note). Settings is the gear.
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: { Task { await viewModel.reload() } }) { content in
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
        .sheet(isPresented: $viewModel.isEditing) {
            EditProfilePlaceholder()
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
                NavRow(verbatim: row.title, subtitle: row.count.formatted(), systemImage: row.systemImage) {
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

/// Stands in for Edit profile (SC-PR6) until that screen is built in this branch.
private struct EditProfilePlaceholder: View {
    var body: some View {
        Text(verbatim: "PR6")
            .font(Theme.Font.largeTitle)
            .presentationDragIndicator(.visible)
    }
}
