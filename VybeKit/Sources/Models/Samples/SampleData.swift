#if DEBUG
import Foundation

/// Preview and test data. Places and Hangouts are the EXAMPLE values from `docs/DATA-MODEL.md` section 4, labelled
/// EXAMPLE, until the real X-C1 content is merged (ADR 004: samples never invent a real-looking venue).
/// People are clearly fake (`user-sample-...`).
public enum SampleData {
    public static let day = Date(timeIntervalSince1970: 1_793_700_000)   // 2026-11-03T10:00:00Z

    public static let cafe = Place(
        id: "place-example-cafe-a1b2", name: "EXAMPLE Café", category: .cafe, city: "Pune", area: "Kothrud",
        address: "EXAMPLE address line, Kothrud", coordinate: Coordinate(latitude: 18.5000, longitude: 73.8000),
        costPerPerson: RupeeRange(lower: 100, upper: 250),
        hours: [OpeningPeriod(weekday: 1, open: "09:00", close: "22:00"),
                OpeningPeriod(weekday: 2, open: "09:00", close: "22:00")],
        photos: [Photo(id: "photo-example-cafe-1", path: "place-example-cafe-a1b2-1.jpg", width: 1600, height: 1200,
                       credit: "EXAMPLE Teammate")],
        verifiedAt: day)

    public static let park = Place(
        id: "place-example-park-e5f6", name: "EXAMPLE Park", category: .parkGarden, city: "Pune", area: "Kothrud",
        address: "EXAMPLE address line, Kothrud", coordinate: Coordinate(latitude: 18.5010, longitude: 73.8020),
        costPerPerson: RupeeRange(lower: 0, upper: 0), hoursNote: "EXAMPLE hours note", verifiedAt: day)

    public static let places = [cafe, park]

    public static let signedInUser = UserProfile(
        id: "user-sample-me", username: "sample.me", displayName: "Sample Me", interests: ["cafes", "parks"],
        friendCount: 1, createdAt: day)

    public static let friend = UserProfile(
        id: "user-sample-friend", username: "sample.friend", displayName: "Sample Friend", friendCount: 1,
        createdAt: day)

    public static let vybeTeam = UserProfile(
        id: "user-vybe-team", username: "vybe", displayName: "Vybe", createdAt: day)

    public static let people = [signedInUser, friend, vybeTeam]

    /// The EXAMPLE Hangout from `docs/DATA-MODEL.md` section 4 (a Pick).
    public static let evening = Hangout(
        id: "hangout-example-evening-c3d4", title: "EXAMPLE Evening Hangout", summary: "EXAMPLE summary text.",
        spots: [Spot(id: "s1", placeID: cafe.id, minutes: 45, note: "EXAMPLE note"),
                Spot(id: "s2", placeID: park.id, minutes: 30)],
        budgetPerPerson: RupeeRange(lower: 150, upper: 400), estimatedMinutes: 120, bestTimes: ["evening"],
        tags: ["good-for-groups"], vibeTags: ["chill"], authorID: vybeTeam.id, isPick: true, createdAt: day,
        updatedAt: day)

    /// A second EXAMPLE Hangout over the same two EXAMPLE places, made by a sample person (not a Pick).
    public static let morning = Hangout(
        id: "hangout-example-morning-g7h8", title: "EXAMPLE Morning Hangout", summary: "EXAMPLE summary text.",
        spots: [Spot(id: "s1", placeID: park.id, minutes: 40), Spot(id: "s2", placeID: cafe.id, minutes: 50)],
        budgetPerPerson: RupeeRange(lower: 100, upper: 250), estimatedMinutes: 90, bestTimes: ["morning"],
        tags: ["outdoors"], vibeTags: ["fresh"], authorID: friend.id, createdAt: day, updatedAt: day)

    public static let hangouts = [evening, morning]
}
#endif
