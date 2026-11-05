#if DEBUG
import Core
import SwiftUI
import UIKit

extension NameAndPhotoViewModel {
    /// The real ViewModel on a throwaway session, optionally with a typed name.
    static func preview(name: String? = nil) -> NameAndPhotoViewModel {
        let deps = AppDependencies.preview()
        let viewModel = NameAndPhotoViewModel(session: deps.session, router: deps.router, processor: PhotoProcessor())
        if let name { viewModel.name = name }
        return viewModel
    }

    /// A small drawn picture (no real person's photo in previews).
    static var previewPhotoData: Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
            UIColor.systemOrange.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 100, y: 100, width: 200, height: 200))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}

private func screen(_ viewModel: NameAndPhotoViewModel) -> some View {
    NavigationStack { NameAndPhotoView(viewModel: viewModel) }
}

#Preview("Empty") { screen(.preview()) }
#Preview("Valid name") { screen(.preview(name: "Riya")) }
#Preview("Name too short") { screen(.preview(name: "R")) }
#Preview("With photo") {
    let viewModel = NameAndPhotoViewModel.preview(name: "Riya")
    screen(viewModel).task { await viewModel.photoPicked(NameAndPhotoViewModel.previewPhotoData) }
}
#Preview("Photo could not be used") {
    let viewModel = NameAndPhotoViewModel.preview(name: "Riya")
    screen(viewModel).task { await viewModel.photoPicked(Data("not a photo".utf8)) }
}
#Preview("Large text") { screen(.preview(name: "R")).dynamicTypeSize(.accessibility3) }
#endif
