// Fixture: banned words only in strings and in type and case names. A Plan, Trace or Stop in a comment is fine.
let title = "Start your Plan" // expect: banned_word_in_string
let hint = "Next stop: Vetal Tekdi" // expect: banned_word_in_string
let caption = "A fun outing with friends" // expect: banned_word_in_string
let button = "Fork this" // expect: banned_word_in_string
let more = "Trace, Node and Organiser" // expect: banned_word_in_string
let saved = "Your saved plans" // expect: banned_word_in_string
let host = "Ask the organizer" // expect: banned_word_in_string

struct TraceCard {} // expect: banned_word_in_type_name
enum HangoutStopKind {} // expect: banned_word_in_type_name
protocol NodeProviding {} // expect: banned_word_in_type_name
final class OrganiserBadge {} // expect: banned_word_in_type_name
typealias Fork = Int // expect: banned_word_in_type_name
struct SavedPlans {} // expect: banned_word_in_type_name
enum OrganizerRole {} // expect: banned_word_in_type_name

enum Step {
    case plan // expect: banned_word_in_case_name
    case savedTrace // expect: banned_word_in_case_name
    case hangout, outing // expect: banned_word_in_case_name
    case traces // expect: banned_word_in_case_name
    case organizer // expect: banned_word_in_case_name
    case remix
    case stopwatch
}

// Must pass: Apple API names, word boundaries, and the words inside comments.
struct PlanetView {}
struct HangoutPlanner {}
let routing = "routing past the planetarium"
func endHangout(_ view: some View, done: Bool) -> some View { view.sensoryFeedback(.stop, trigger: done) }
func handle(_ s: HapticStep) { switch s { case .stop: break; default: break } }
