#if DEBUG
import Core
import SwiftUI

extension SearchViewModel {
    /// The real ViewModel on the stub repositories, in one state, with an optional query already typed.
    static func preview(_ mode: StubMode, query: String = "") -> SearchViewModel {
        let deps = AppDependencies.preview(mode)
        let viewModel = SearchViewModel(
            search: deps.search, hangouts: deps.hangouts, libraryStore: deps.libraryStore, session: deps.session,
            router: deps.router, debounce: .milliseconds(10))
        viewModel.query = query
        return viewModel
    }
}

#Preview("Before typing") { NavigationStack { SearchView(viewModel: .preview(.loaded)) } }
#Preview("Results") { NavigationStack { SearchView(viewModel: .preview(.loaded, query: "a")) } }
#Preview("No results") { NavigationStack { SearchView(viewModel: .preview(.empty, query: "zzz")) } }
#Preview("Error") { NavigationStack { SearchView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { SearchView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { SearchView(viewModel: .preview(.loaded, query: "a")) }
        .dynamicTypeSize(.accessibility3)
}
#endif
