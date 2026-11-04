import Core
import Models
import Testing
@testable import EditorFeature

/// Builds every entry point of `EditorScreens` (task F-16).
@MainActor
struct EditorScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = EditorScreens.editorCover(.new, deps)
        _ = EditorScreens.editorCover(.draft("h1"), deps)
        _ = EditorScreens.editorCover(.remix("h1"), deps)
        _ = EditorScreens.view(for: .suggestPlace, deps)
        _ = EditorScreens.suggestPlaceSheet(deps)
    }
}
