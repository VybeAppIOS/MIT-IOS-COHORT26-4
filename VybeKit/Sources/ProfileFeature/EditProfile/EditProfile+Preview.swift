#if DEBUG
import Core
import Models
import SwiftUI

extension EditProfileViewModel {
    /// The real ViewModel on the stubs, editing the sample "me". `bio` overrides the bio to show the limit.
    static func preview(_ mode: StubMode = .loaded, bio: String? = nil) -> EditProfileViewModel {
        let deps = AppDependencies.preview(mode)
        let viewModel = EditProfileViewModel(profile: SampleData.signedInUser, profiles: deps.profiles,
                                             auth: deps.auth, session: deps.session)
        if let bio { viewModel.bio = bio }
        return viewModel
    }
}

#Preview("Edit profile") { EditProfileView(viewModel: .preview()) }
#Preview("Bio too long") {
    EditProfileView(viewModel: .preview(bio: String(repeating: "Chai near Karve Road, then Vetal Tekdi. ", count: 5)))
}
#Preview("Large text") {
    EditProfileView(viewModel: .preview())
        .dynamicTypeSize(.accessibility3)
}
#endif
