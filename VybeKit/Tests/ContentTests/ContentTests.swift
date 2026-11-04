import Foundation
import LocalData
import Models
import Testing

/// The bundled team content (`LocalData/Resources/Content`) must be sound. Passes with an empty folder; checks every
/// file as soon as real content (task X-C1) is added.
struct ContentTests {
    private let loader = ContentLoader.bundled

    @Test func everyFileLoads() throws {
        _ = try loader.load()
    }

    @Test func idsAreUnique() throws {
        let content = try loader.load()
        #expect(Set(content.places.map(\.id)).count == content.places.count, "duplicate Place ID")
        #expect(Set(content.hangouts.map(\.id)).count == content.hangouts.count, "duplicate Hangout ID")
    }

    @Test func everySpotPointsToAnExistingPlace() throws {
        let content = try loader.load()
        let placeIDs = Set(content.places.map(\.id))
        for hangout in content.hangouts {
            for spot in hangout.spots {
                #expect(placeIDs.contains(spot.placeID), "\(hangout.id): Spot \(spot.id) points to a missing Place")
            }
            #expect(Set(hangout.spots.map(\.id)).count == hangout.spots.count, "\(hangout.id): duplicate Spot ID")
        }
    }

    @Test func everyHangoutHasTwoToTenSpots() throws {
        for hangout in try loader.load().hangouts {
            #expect((2...10).contains(hangout.spots.count), "\(hangout.id) has \(hangout.spots.count) Spots")
        }
    }

    @Test func coordinatesAreInsidePune() throws {
        for place in try loader.load().places {
            #expect((18.3...18.7).contains(place.coordinate.latitude), "\(place.id): latitude")
            #expect((73.6...74.1).contains(place.coordinate.longitude), "\(place.id): longitude")
        }
    }

    @Test func everyPhotoFileExists() throws {
        for place in try loader.load().places {
            for photo in place.photos {
                let file = loader.photosDirectory.appending(path: photo.path)
                #expect(FileManager.default.fileExists(atPath: file.path), "\(place.id): missing photo \(photo.path)")
            }
        }
    }

    /// Samples never invent data: a sample with the same ID as bundled content must equal it exactly.
    @Test func samplesEqualTheirBundledFiles() throws {
        let content = try loader.load()
        for place in SampleData.places {
            if let bundled = content.places.first(where: { $0.id == place.id }) {
                #expect(bundled == place, "SampleData Place \(place.id) differs from its bundled JSON file")
            }
        }
        for hangout in SampleData.hangouts {
            if let bundled = content.hangouts.first(where: { $0.id == hangout.id }) {
                #expect(bundled == hangout, "SampleData Hangout \(hangout.id) differs from its bundled JSON file")
            }
        }
    }
}
