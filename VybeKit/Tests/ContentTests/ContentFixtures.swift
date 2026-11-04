import Foundation

/// EXAMPLE JSON copied from `docs/DATA-MODEL.md` section 4. These are not real places.
enum ContentFixtures {
    static let examplePlace = """
    {
      "schemaVersion": 1,
      "id": "place-example-cafe-a1b2",
      "name": "EXAMPLE Café",
      "category": "cafe",
      "city": "Pune",
      "area": "Kothrud",
      "address": "EXAMPLE address line, Kothrud",
      "coordinate": { "latitude": 18.5000, "longitude": 73.8000 },
      "costPerPerson": { "lower": 100, "upper": 250 },
      "hours": [
        { "weekday": 1, "open": "09:00", "close": "22:00" },
        { "weekday": 2, "open": "09:00", "close": "22:00" }
      ],
      "hoursNote": null,
      "photos": [
        { "id": "photo-example-cafe-1", "path": "place-example-cafe-a1b2-1.jpg",
          "width": 1600, "height": 1200, "credit": "EXAMPLE Teammate" }
      ],
      "applePlaceID": null,
      "status": "approved",
      "verifiedAt": "2026-11-03T10:00:00Z"
    }
    """

    static let exampleHangout = """
    {
      "schemaVersion": 1,
      "id": "hangout-example-evening-c3d4",
      "title": "EXAMPLE Evening Hangout",
      "summary": "EXAMPLE summary text.",
      "spots": [
        { "id": "s1", "placeID": "place-example-cafe-a1b2", "minutes": 45, "note": "EXAMPLE note" },
        { "id": "s2", "placeID": "place-example-park-e5f6", "minutes": 30, "note": null }
      ],
      "budgetPerPerson": { "lower": 150, "upper": 400 },
      "estimatedMinutes": 120,
      "bestTimes": ["evening"],
      "tags": ["good-for-groups"],
      "vibeTags": ["chill"],
      "authorID": "user-vybe-team",
      "isPick": true,
      "status": "published",
      "remixedFromID": null,
      "remixedFromPlaceIDs": null,
      "createdAt": "2026-11-03T10:00:00Z",
      "updatedAt": "2026-11-03T10:00:00Z"
    }
    """

    /// EXAMPLE trek, not a real place.
    static let exampleTrek = """
    {
      "id": "place-example-trek-9z9z", "name": "EXAMPLE Hill", "category": "trek", "city": "Pune",
      "area": "Kothrud", "address": "EXAMPLE", "coordinate": { "latitude": 18.51, "longitude": 73.81 },
      "costPerPerson": { "lower": 0, "upper": 0 }, "hours": [], "hoursNote": "EXAMPLE: daylight only",
      "photos": [], "applePlaceID": "EXAMPLE-APPLE-ID", "status": "closedByAuthorities",
      "trekInfo": { "difficulty": "moderate", "season": "EXAMPLE season", "startPoint": "EXAMPLE gate",
                    "safetyNote": "EXAMPLE note" },
      "verifiedAt": "2026-11-03T10:00:00.500Z"
    }
    """
}
