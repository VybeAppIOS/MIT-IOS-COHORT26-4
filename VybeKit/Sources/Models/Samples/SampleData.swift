#if DEBUG
import Foundation

/// Preview and test data. The two Places are real Kothrud venues taken from the X-C1 draft (names, addresses, prices
/// and hours are the unverified draft values: Lohitaksh and Shreya have to confirm them). The Hangouts are made up
/// from those two Places. The IDs are still the old `...-example-...` ones, because tests and sample posts use them.
/// The coordinates are NOT the venues' real positions (the draft has none yet): they are the old placeholders.
/// People are clearly fake (`user-sample-...`).
public enum SampleData {
    public static let day = Date(timeIntervalSince1970: 1_793_700_000)   // 2026-11-03T10:00:00Z

    public static let cafe = Place(
        id: "place-example-cafe-a1b2", name: "Amarii Cafe", category: .cafe, city: "Pune", area: "Kothrud",
        address: "Roopnagari Society, near Apple Unisex Salon, Mayur Colony, Kothrud, Pune 411038",
        coordinate: Coordinate(latitude: 18.5000, longitude: 73.8000),
        costPerPerson: RupeeRange(lower: 250, upper: 500),
        hours: (1...7).map { OpeningPeriod(weekday: $0, open: "09:00", close: "23:00") },
        photos: [Photo(id: "photo-example-cafe-1", path: "place-example-cafe-a1b2-1.jpg", width: 1600, height: 1200,
                       credit: "Vybe team")],
        verifiedAt: day)

    public static let park = Place(
        id: "place-example-park-e5f6", name: "Thorat Garden", category: .parkGarden, city: "Pune", area: "Kothrud",
        address: "DP Road, next to Yashwantrao Natyagruha, Mayur Colony, Kothrud, Pune 411038",
        coordinate: Coordinate(latitude: 18.5010, longitude: 73.8020),
        costPerPerson: RupeeRange(lower: 0, upper: 0), hoursNote: "Open 6 to 11 am and 4 to 8 pm, every day.",
        verifiedAt: day)

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

    /// An evening Hangout over the two Places (a Pick).
    public static let evening = Hangout(
        id: "hangout-example-evening-c3d4", title: "Coffee, Then a Garden Walk",
        summary: "Start with coffee and snacks at Amarii Cafe, then walk it off in Thorat Garden.",
        spots: [Spot(id: "s1", placeID: cafe.id, minutes: 45, note: "Coffee, snacks and conversations."),
                Spot(id: "s2", placeID: park.id, minutes: 30)],
        budgetPerPerson: RupeeRange(lower: 150, upper: 400), estimatedMinutes: 120, bestTimes: ["evening"],
        tags: ["good-for-groups"], vibeTags: ["chill"], authorID: vybeTeam.id, isPick: true, createdAt: day,
        updatedAt: day)

    /// A second Hangout over the same two Places, made by a sample person (not a Pick).
    public static let morning = Hangout(
        id: "hangout-example-morning-g7h8", title: "Early Walk, Then Coffee",
        summary: "Beat the crowds at Thorat Garden, then settle in at Amarii Cafe.",
        spots: [Spot(id: "s1", placeID: park.id, minutes: 40), Spot(id: "s2", placeID: cafe.id, minutes: 50)],
        budgetPerPerson: RupeeRange(lower: 100, upper: 250), estimatedMinutes: 90, bestTimes: ["morning"],
        tags: ["outdoors"], vibeTags: ["fresh"], authorID: friend.id, createdAt: day, updatedAt: day)

    public static let hangouts = [evening, morning]
}
#endif
