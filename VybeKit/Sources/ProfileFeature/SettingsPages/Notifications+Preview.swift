#if DEBUG
import Core
import Models
import SwiftUI

extension NotificationsViewModel {
    /// Kept in memory only, for previews. `failing` makes the first read fail (the error state).
    static func preview(failing: Bool = false) -> NotificationsViewModel {
        NotificationsViewModel(
            loadChoices: {
                if failing { throw AppError.offline }
                return NotificationChoices()
            },
            saveChoices: { _ in })
    }
}

#Preview("Loaded") { NavigationStack { NotificationsView(viewModel: .preview()) } }
#Preview("Error") { NavigationStack { NotificationsView(viewModel: .preview(failing: true)) } }
#Preview("Large text") {
    NavigationStack { NotificationsView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
