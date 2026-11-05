#if DEBUG
import Core
import Models
import SwiftUI

extension DraftsViewModel {
    /// The real ViewModel on the stubs. `withDraft` puts a Remix of the EXAMPLE morning Hangout in Drafts.
    static func preview(_ mode: StubMode = .loaded, withDraft: Bool = true) -> DraftsViewModel {
        let deps = AppDependencies.preview(mode)
        if withDraft { Task { await deps.libraryStore.saveDraft(sampleDraft) } }
        return DraftsViewModel(places: deps.places, photos: deps.photos, libraryStore: deps.libraryStore,
                               router: deps.router)
    }

    /// A Remix of the EXAMPLE morning Hangout, as a Draft.
    static var sampleDraft: Hangout {
        let original = SampleData.morning
        return Hangout(id: "hangout-draft-sample", title: "EXAMPLE Morning Hangout, my way", summary: original.summary,
                       spots: original.spots, budgetPerPerson: original.budgetPerPerson,
                       estimatedMinutes: original.estimatedMinutes, authorID: SampleData.signedInUser.id,
                       status: .draft, remixedFromID: original.id, createdAt: SampleData.day, updatedAt: SampleData.day)
    }
}

#Preview("Loaded") { NavigationStack { DraftsView(viewModel: .preview()) } }
#Preview("Empty") { NavigationStack { DraftsView(viewModel: .preview(withDraft: false)) } }
#Preview("Error") { NavigationStack { DraftsView(viewModel: .preview(.failing, withDraft: false)) } }
#Preview("Loading") { NavigationStack { DraftsView(viewModel: .preview(.neverReturns, withDraft: false)) } }
#Preview("Large text") {
    NavigationStack { DraftsView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
