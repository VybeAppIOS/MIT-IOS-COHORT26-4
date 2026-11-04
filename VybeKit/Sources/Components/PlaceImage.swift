import CoreGraphics
import Design
import SwiftUI

/// A photo loaded through `ImageLoader.shared`: downsampled to the size it is drawn at, cached, and faded in
/// (a plain fade with Reduce Motion). While loading it shows a quiet placeholder; if the photo cannot be loaded it
/// shows an icon instead, never a crash.
///
/// Pass `accessibilityLabel` only when the photo means something on its own; otherwise it is decorative and
/// VoiceOver skips it.
public struct PlaceImage: View {
    private let url: URL?
    private let aspectRatio: CGFloat?
    private let contentMode: ContentMode
    private let accessibilityText: String?

    @Environment(\.displayScale) private var displayScale
    @State private var phase = Phase.loading
    @State private var size = CGSize.zero

    public init(url: URL?, aspectRatio: CGFloat? = nil, contentMode: ContentMode = .fill,
                accessibilityLabel: String? = nil) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
        self.accessibilityText = accessibilityLabel
    }

    enum Phase {
        case loading
        case loaded(CGImage)
        case failed
    }

    /// What `.task(id:)` watches: a new URL or a new size starts a new load.
    private struct Request: Hashable {
        let url: URL?
        let pixels: Int
    }

    public var body: some View {
        Rectangle()
            .fill(Theme.Color.surfaceRaised)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay { content }
            .clipped()
            .onGeometryChange(for: CGSize.self, of: { $0.size }, action: { size = $0 })
            .task(id: request) { await load() }
            .modifier(PhotoAccessibility(label: accessibilityText))
    }

    @ViewBuilder private var content: some View {
        switch phase {
        case .loading:
            EmptyView()
        case .loaded(let image):
            Image(decorative: image, scale: displayScale)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .transition(.opacity)
        case .failed:
            Image(systemName: url == nil ? "photo" : "exclamationmark.triangle")
                .font(Theme.Font.title2)
                .foregroundStyle(Theme.Color.textSecondary)
                .accessibilityLabel(Text(verbatim: ComponentStrings.photoUnavailable))
        }
    }

    private var request: Request {
        Request(url: url, pixels: Int(max(size.width, size.height) * displayScale))
    }

    private func load() async {
        guard let url else {
            phase = .failed
            return
        }
        let pixels = request.pixels
        guard pixels > 0 else { return }   // not laid out yet; the task runs again once it has a size
        do {
            let image = try await ImageLoader.shared.image(at: url, maxPixelSize: CGFloat(pixels))
            withVybeAnimation(Theme.Motion.standard) { phase = .loaded(image) }
        } catch is CancellationError {
            return
        } catch {
            phase = .failed
        }
    }
}

/// A labelled photo is one VoiceOver element with its label and the image trait; an unlabelled one is hidden.
private struct PhotoAccessibility: ViewModifier {
    let label: String?

    func body(content: Content) -> some View {
        if let label {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: label))
                .accessibilityAddTraits(.isImage)
        } else {
            content.accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

/// A file that does not exist: shows the failure icon.
private let missingFile = URL(filePath: "/EXAMPLE/missing-photo.jpg")

#Preview("No URL, missing file") {
    VStack(spacing: Theme.Spacing.large) {
        PlaceImage(url: nil, aspectRatio: 16 / 9)
        PlaceImage(url: missingFile, aspectRatio: 4 / 3, accessibilityLabel: "Vetal Tekdi at sunset")
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}

#Preview("Square thumbnail") {
    PlaceImage(url: missingFile, aspectRatio: 1)
        .frame(width: 72)
        .clipShape(.rect(cornerRadius: Theme.Radius.small))
        .padding(Theme.Spacing.large)
}
