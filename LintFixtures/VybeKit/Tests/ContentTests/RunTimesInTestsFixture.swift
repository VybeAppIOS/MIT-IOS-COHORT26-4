// Fixture (must pass): package test code may use RunTimes to test it (run_times_confined checks app code only).
import Testing

struct RunTimesInTestsFixture {
    @Test func roundTrips() {
        let times: RunTimes? = nil
        _ = times
    }
}
