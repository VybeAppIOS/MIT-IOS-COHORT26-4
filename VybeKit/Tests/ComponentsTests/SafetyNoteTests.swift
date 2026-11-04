import Testing
@testable import Components
import Design

@MainActor
struct SafetyNoteTests {
    @Test func warningIsSpokenAsAWarning() {
        let note = SafetyNote("Slippery after rain.", style: .warning)

        #expect(note.spokenLabel == "Warning. Slippery after rain.")
    }

    @Test func infoIsSpokenAsANote() {
        let note = SafetyNote("Carry water.", style: .info)

        #expect(note.spokenLabel == "Note. Carry water.")
    }

    @Test func monsoonBannerIsAShortWarning() {
        let note = SafetyNote.monsoon()

        #expect(note.spokenLabel.hasPrefix("Warning. "))
        #expect(SharedStrings.safetyNoteMonsoon.count < 120)
        #expect(!SharedStrings.safetyNoteMonsoon.hasPrefix("component."))
    }
}
