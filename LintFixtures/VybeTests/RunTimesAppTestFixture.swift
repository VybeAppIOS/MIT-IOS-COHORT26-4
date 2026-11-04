// Fixture (must pass): app test code may use RunTimes too (run_times_confined checks app code only).
import Testing

struct RunTimesAppTestFixture {
    @Test func appTestCanSeeRunTimes() {
        let times: RunTimes? = nil
        _ = times
    }
}
