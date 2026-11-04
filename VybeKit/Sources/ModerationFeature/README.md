# ModerationFeature

Screens: R1-R2, AD1-AD3 (see `docs/IA.md` section 4).

May import: Models, Core, Design, Components. **Never** another Feature, LocalData or Remote.

One folder per screen: `<Screen>/<Screen>View.swift`, `<Screen>ViewModel.swift`, `<Screen>+Preview.swift`. Tests: `Tests/ModerationFeatureTests/`. Copy the template in `docs/templates/new-screen/`.

Public API: only `<Name>Screens.swift` (it builds this feature's screens from `AppDependencies`). Views and ViewModels are `internal`; tests use `@testable import` (`docs/adr/002-feature-owned-screens.md`). Wire a screen by replacing its placeholder `case` there.
