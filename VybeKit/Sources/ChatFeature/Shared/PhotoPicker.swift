import PhotosUI
import SwiftUI

/// The bridge between the system photo picker and a ViewModel: PhotosUI belongs to the View layer, so it turns the
/// picked items into bytes here and hands them on. If any picture cannot be read, nothing is handed on and `onFailed`
/// is called instead.
private struct PhotoPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let limit: Int
    let onPicked: ([Data]) async -> Void
    let onFailed: () -> Void
    @State private var items: [PhotosPickerItem] = []

    func body(content: Content) -> some View {
        content
            .photosPicker(
                isPresented: $isPresented, selection: $items, maxSelectionCount: limit, matching: .images,
                photoLibrary: .shared())
            .onChange(of: items) { _, picked in
                guard !picked.isEmpty else { return }
                Task {
                    var pictures: [Data] = []
                    for item in picked {
                        if let data = try? await item.loadTransferable(type: Data.self) { pictures.append(data) }
                    }
                    items = []
                    if pictures.count == picked.count { await onPicked(pictures) } else { onFailed() }
                }
            }
    }
}

extension View {
    /// Shows the system photo picker (up to `limit` pictures) while `isPresented` is true.
    func photoPicker(
        isPresented: Binding<Bool>, limit: Int, onPicked: @escaping ([Data]) async -> Void,
        onFailed: @escaping () -> Void
    ) -> some View {
        modifier(PhotoPickerModifier(isPresented: isPresented, limit: limit, onPicked: onPicked, onFailed: onFailed))
    }
}
