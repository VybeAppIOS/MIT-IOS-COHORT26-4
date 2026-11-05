import Components
import Core
import Foundation
import Models

/// The view-ready values of the editor: words, rows and the time estimate. They only read what the view model holds,
/// so they live here and keep `EditorViewModel` itself short.
extension EditorViewModel {
    var screenTitle: String {
        switch start {
        case .new: String(localized: "editor.title.new", bundle: #bundle)
        case .draft: String(localized: "editor.title.draft", bundle: #bundle)
        case .remix: String(localized: "editor.title.remix", bundle: #bundle)
        }
    }

    var spotRows: [SpotRowData] {
        spots.enumerated().compactMap { offset, spot in
            guard let place = placesByID[spot.placeID] else { return nil }
            let twice = spots.filter { $0.placeID == spot.placeID }.count > 1
            return SpotRowData(spot: spot, place: place, order: offset + 1, total: spots.count,
                               hasDuplicateWarning: twice)
        }
    }

    var estimatedMinutes: Int { minutesOverride ?? spots.compactMap(\.minutes).reduce(0, +) }
    var estimatedText: String { HangoutRules.roundedDuration(estimatedMinutes) }

    func minutes(for id: SpotID) -> Int { spots.first { $0.id == id }?.minutes ?? 0 }
    func note(for id: SpotID) -> String { spots.first { $0.id == id }?.note ?? "" }

    /// "45 min here".
    func minutesText(for id: SpotID) -> String {
        String(format: String(localized: "editor.spot.minutes", bundle: #bundle), minutes(for: id))
    }
}
