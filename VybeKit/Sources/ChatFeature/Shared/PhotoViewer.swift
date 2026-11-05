import Components
import Design
import Foundation
import SwiftUI

/// One picture in the full-screen viewer: a plain value (no ViewModel, shared by Conversation and Group photos).
struct ViewerPhoto: Identifiable, Equatable {
    let id: String
    let url: URL?
    /// What VoiceOver says, for example "Photo 2 of 5".
    let label: String
}

/// Everything the viewer needs: the pictures to swipe between, which one to start on, and the word for Close.
/// The ViewModel builds it (it owns the words); `fullScreenCover(item:)` shows it.
struct PhotoViewerItem: Identifiable, Equatable {
    let photos: [ViewerPhoto]
    let startIndex: Int
    let closeLabel: String

    var id: String { photos.indices.contains(startIndex) ? photos[startIndex].id : "none" }

    /// `ids` and `urls` go together, one pair per picture. The labels say the place in the set ("Photo 2 of 5").
    init(ids: [String], urls: [URL?], startIndex: Int) {
        let count = urls.count
        photos = urls.enumerated().map { index, url in
            ViewerPhoto(
                id: ids[index], url: url,
                label: count > 1
                    ? String(localized: "chat.photo.position \(index + 1) \(count)", bundle: #bundle)
                    : String(localized: "chat.photo.single", bundle: #bundle))
        }
        self.startIndex = startIndex
        closeLabel = String(localized: "chat.photo.close", bundle: #bundle)
    }
}

/// The full-screen photo viewer: swipe left and right between the pictures, Close in the corner. System page view and
/// a system navigation bar; no glass on the photos themselves.
struct PhotoViewer: View {
    let item: PhotoViewerItem
    @State private var selection: Int
    @Environment(\.dismiss) private var dismiss

    init(item: PhotoViewerItem) {
        self.item = item
        _selection = State(initialValue: item.startIndex)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(Array(item.photos.enumerated()), id: \.element.id) { index, photo in
                    PlaceImage(url: photo.url, contentMode: .fit, accessibilityLabel: photo.label)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: item.photos.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .background(Theme.Color.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(Text(verbatim: item.closeLabel))
                }
            }
        }
    }
}

#if DEBUG
#Preview("Three photos") {
    PhotoViewer(item: PhotoViewerItem(ids: ["a", "b", "c"], urls: [nil, nil, nil], startIndex: 1))
}
#Preview("One photo") {
    PhotoViewer(item: PhotoViewerItem(ids: ["a"], urls: [nil], startIndex: 0))
}
#Preview("Large text") {
    PhotoViewer(item: PhotoViewerItem(ids: ["a", "b"], urls: [nil, nil], startIndex: 0))
        .dynamicTypeSize(.accessibility3)
}
#endif
