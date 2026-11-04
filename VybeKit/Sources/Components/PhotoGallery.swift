import Design
import SwiftUI

/// One photo in a gallery: where it is, who took it, and what it shows (for VoiceOver).
public struct GalleryPhoto: Hashable, Sendable, Identifiable {
    public let id: String
    public let url: URL?
    public let credit: String?
    public let description: String?

    public init(id: String, url: URL?, credit: String? = nil, description: String? = nil) {
        self.id = id
        self.url = url
        self.credit = credit
        self.description = description
    }
}

/// Swipeable photos with page dots and the credit line of the photo on screen (Hangout detail header, Spot sheet).
/// With no photos it shows one placeholder; with one photo there are no dots.
public struct PhotoGallery: View {
    private let photos: [GalleryPhoto]
    private let aspectRatio: CGFloat
    @State private var selection: String?

    public init(photos: [GalleryPhoto], aspectRatio: CGFloat = 4 / 3) {
        self.photos = photos
        self.aspectRatio = aspectRatio
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            pages
            if let credit = currentPhoto?.credit {
                Text(verbatim: ComponentStrings.photoCredit(credit))
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .padding(.horizontal, Theme.Spacing.large)
            }
        }
    }

    @ViewBuilder private var pages: some View {
        if photos.isEmpty {
            PlaceImage(url: nil, aspectRatio: aspectRatio)
        } else {
            TabView(selection: $selection) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { offset, photo in
                    PlaceImage(url: photo.url, aspectRatio: aspectRatio,
                               accessibilityLabel: label(for: photo, page: offset + 1))
                        .tag(Optional(photo.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .aspectRatio(aspectRatio, contentMode: .fit)
        }
    }

    private var currentPhoto: GalleryPhoto? {
        photos.first { $0.id == selection } ?? photos.first
    }

    /// "Photo 2 of 5, <description>": the position is always read, the description when there is one.
    private func label(for photo: GalleryPhoto, page: Int) -> String {
        let position = ComponentStrings.galleryPage(page, of: photos.count)
        guard let description = photo.description else { return position }
        return "\(position), \(description)"
    }
}

// MARK: - Previews

private let previewPhotos = [
    GalleryPhoto(id: "p1", url: nil, credit: "EXAMPLE Teammate", description: "EXAMPLE café front"),
    GalleryPhoto(id: "p2", url: URL(filePath: "/EXAMPLE/missing.jpg"), credit: "EXAMPLE Friend"),
    GalleryPhoto(id: "p3", url: nil)
]

#Preview("Three photos with credits") {
    PhotoGallery(photos: previewPhotos)
        .background(Theme.Color.surface)
}

#Preview("One photo, no dots") {
    PhotoGallery(photos: Array(previewPhotos.prefix(1)))
}

#Preview("No photos") {
    PhotoGallery(photos: [])
}

#Preview("Large text") {
    PhotoGallery(photos: previewPhotos)
        .dynamicTypeSize(.accessibility3)
}
