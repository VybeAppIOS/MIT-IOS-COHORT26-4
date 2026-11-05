import Components
import Design
import SwiftUI

/// Layout only: every value comes from `GroupPhotosViewModel`, every tap goes to it.
struct GroupPhotosView: View {
    @State private var viewModel: GroupPhotosViewModel
    /// The smallest a picture is drawn; it grows with the text size, so large text gets fewer, bigger columns.
    @ScaledMetric(relativeTo: .body) private var tileMinimum = Theme.Size.minTapTarget * 2.5

    init(viewModel: GroupPhotosViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.retry() } },
            content: { content in grid(content) },
            placeholder: { grid(GroupPhotosContent(photos: Self.placeholders)) },
            empty: { EmptyStateView(systemImage: "photo.on.rectangle", message: viewModel.emptyMessage) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.Color.surface)
        .task { await viewModel.run() }
        .fullScreenCover(item: $viewModel.viewer) { PhotoViewer(item: $0) }
    }

    private func grid(_ content: GroupPhotosContent) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: tileMinimum), spacing: Theme.Spacing.small)],
                spacing: Theme.Spacing.small
            ) {
                ForEach(content.photos) { photo in
                    Button { viewModel.photoTapped(photo.id) } label: {
                        PlaceImage(url: photo.url, aspectRatio: 1, contentMode: .fill, accessibilityLabel: photo.label)
                            .clipShape(.rect(cornerRadius: Theme.Radius.small))
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.small)
        }
    }

    private static let placeholders = (0..<9).map { ViewerPhoto(id: "placeholder-\($0)", url: nil, label: "") }
}
