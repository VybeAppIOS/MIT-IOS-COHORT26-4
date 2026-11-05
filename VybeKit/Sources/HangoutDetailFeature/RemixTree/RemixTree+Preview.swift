#if DEBUG
import Core
import Models
import SwiftUI

extension RemixTreeViewModel {
    /// The real ViewModel on the stub repositories. `hangouts` replaces the sample list, so a preview can include a
    /// Remix (an EXAMPLE copy of a sample Hangout pointing at the Evening Hangout).
    static func preview(
        _ mode: StubMode = .loaded, id: HangoutID = SampleData.evening.id,
        hangouts: [Hangout] = Hangout.previewTree
    ) -> RemixTreeViewModel {
        let deps = AppDependencies.preview(mode)
        return RemixTreeViewModel(
            id: id, hangouts: StubHangoutRepository(mode: mode, hangouts: hangouts), places: deps.places,
            profiles: deps.profiles, photos: deps.photos, library: deps.libraryStore, session: deps.session,
            router: deps.router)
    }
}

extension Hangout {
    /// The Morning Hangout, remixed from the Evening Hangout.
    static var previewRemix: Hangout {
        var remix = SampleData.morning
        remix.remixedFromID = SampleData.evening.id
        return remix
    }

    /// The Evening Hangout and one Remix of it.
    static var previewTree: [Hangout] { [SampleData.evening, previewRemix] }
}

private func tree(_ viewModel: RemixTreeViewModel) -> some View {
    NavigationStack { RemixTreeView(viewModel: viewModel) }
}

#Preview("Remixes") { tree(.preview()) }
#Preview("A Remix and its original") { tree(.preview(id: Hangout.previewRemix.id)) }
#Preview("Nobody has remixed yet") { tree(.preview(hangouts: SampleData.hangouts)) }
#Preview("Loading") { tree(.preview(.neverReturns)) }
#Preview("Error") { tree(.preview(.failing)) }
#Preview("Large text") { tree(.preview()).dynamicTypeSize(.accessibility3) }
#endif
