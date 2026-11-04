import Foundation
import Testing
@testable import Models

struct RunAndProfileTests {
    private let day = Date(timeIntervalSince1970: 1_793_700_000)

    private func exampleRun() -> HangoutRun {
        HangoutRun(
            id: "run-example-1", hangoutID: "hangout-example-evening-c3d4", runnerID: "user-sample-1", state: .posted,
            visits: [Visit(spotID: "s1", placeID: "place-example-cafe-a1b2", order: 1),
                     Visit(spotID: "s2", placeID: "place-example-park-e5f6", order: 2)],
            durationMinutes: 170, caption: "EXAMPLE caption", coverPhotoID: "photo-example-1", tags: ["chill"],
            visibility: .public, audience: .friends,
            card: RunCardCopy(hangoutTitle: "EXAMPLE Evening Hangout", totalSpots: 2,
                              budgetPerPerson: RupeeRange(lower: 150, upper: 400),
                              runnerUsername: "sample.one", runnerDisplayName: "Sample One"),
            likeCount: 3, commentCount: 1, postedAt: day)
    }

    @Test func runRoundTrips() throws {
        let run = exampleRun()
        let data = try JSONCoding.encoder.encode(run)
        #expect(try JSONCoding.decoder.decode(HangoutRun.self, from: data) == run)
    }

    @Test func runStatesAndVisibilityUseTheirWords() throws {
        let data = try JSONCoding.encoder.encode([RunState.live, .done, .scheduled, .posted])
        #expect(String(bytes: data, encoding: .utf8) == #"["live","done","scheduled","posted"]"#)
        let visibility = try JSONCoding.encoder.encode([Visibility.public, .friends])
        #expect(String(bytes: visibility, encoding: .utf8) == #"["public","friends"]"#)
    }

    /// Owner-only times must never appear on the run (ADR 004 and 006).
    @Test func runCarriesNoExactTimes() throws {
        let object = try JSONSerialization.jsonObject(with: JSONCoding.encoder.encode(exampleRun()))
        let keys = Set(try #require(object as? [String: Any]).keys)
        #expect(keys.isDisjoint(with: ["startedAt", "endedAt", "visitedAt", "times"]))
        let visits = try #require((object as? [String: Any])?["visits"] as? [[String: Any]])
        #expect(visits.allSatisfy { Set($0.keys) == ["spotID", "placeID", "order"] })
    }

    @Test func runTimesEncodeVisitedAtAsAnObject() throws {
        let times = RunTimes(startedAt: day, endedAt: day.addingTimeInterval(3600), visitedAt: ["s1": day])
        let data = try JSONCoding.encoder.encode(times)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["visitedAt"] is [String: String])
        #expect(try JSONCoding.decoder.decode(RunTimes.self, from: data) == times)
    }

    @Test func liveRunTimesStartWithoutAnEnd() throws {
        let times = RunTimes(startedAt: day)
        #expect(times.endedAt == nil && times.visitedAt.isEmpty)
    }

    // MARK: People

    @Test func settingsDefaultsAreTheSafeOnes() {
        let settings = UserSettings()
        #expect(settings.whoCanComment == .friends)
        #expect(settings.whoCanAddMeToGroups == .askMe)
        #expect(settings.defaultAudience == .friends)
        #expect(settings.showMeInSearch)
    }

    @Test func missingSettingsFallBackToDefaults() throws {
        let decoded = try JSONCoding.decoder.decode(UserSettings.self, from: Data("{}".utf8))
        #expect(decoded == UserSettings())
        let partial = try JSONCoding.decoder.decode(UserSettings.self, from: Data(#"{"showMeInSearch":false}"#.utf8))
        #expect(partial == UserSettings(showMeInSearch: false))
    }

    @Test func profileRoundTrips() throws {
        let profile = UserProfile(
            id: "user-sample-1", username: "sample.one", displayName: "Sample One", bio: "EXAMPLE bio",
            isPrivate: true, interests: ["cafes", "treks"], friendCount: 12,
            settings: UserSettings(whoCanComment: .nobody, defaultAudience: .friends), createdAt: day)
        let data = try JSONCoding.encoder.encode(profile)
        let decoded = try JSONCoding.decoder.decode(UserProfile.self, from: data)
        #expect(decoded == profile)
        #expect(decoded.photo == nil && decoded.deletedAt == nil)
    }

    @Test func profileDecodesWithEmptySettingsObject() throws {
        let json = """
        {"id":"user-sample-2","username":"sample.two","displayName":"Sample Two","isPrivate":false,
         "interests":[],"friendCount":0,"settings":{},"createdAt":"2026-11-03T10:00:00Z"}
        """
        let profile = try JSONCoding.decoder.decode(UserProfile.self, from: Data(json.utf8))
        #expect(profile.settings == UserSettings())
    }

    @Test func accountPrivateRoundTrips() throws {
        let account = AccountPrivate(dateOfBirth: day, confirmed18: true)
        let data = try JSONCoding.encoder.encode(account)
        #expect(try JSONCoding.decoder.decode(AccountPrivate.self, from: data) == account)
    }
}
