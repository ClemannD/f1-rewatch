import Foundation

// MARK: - Region

enum Region: String, CaseIterable, Identifiable, Codable {
    case us = "us"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .us: "United States"
        }
    }

    var flag: String {
        switch self {
        case .us: "🇺🇸"
        }
    }

    /// Resource name of the bundled catalog JSON for this region.
    var catalogResource: String {
        switch self {
        case .us: "US-f1-tv-archive-catalog"
        }
    }
}

// MARK: - F1TV Content Type (what F1TV offers)

enum F1TVContentType: String, Codable, CaseIterable {
    case race = "race"
    case extendedHighlights = "extended_highlights"
    case highlights = "highlights"
    case seasonReview = "season-review"

    var label: String {
        switch self {
        case .race: "Full Race"
        case .extendedHighlights: "Extended Highlights"
        case .highlights: "Highlights"
        case .seasonReview: "Season Recap"
        }
    }

    var systemImage: String {
        switch self {
        case .race: "play.circle.fill"
        case .extendedHighlights: "film.fill"
        case .highlights: "film"
        case .seasonReview: "list.bullet.rectangle.fill"
        }
    }
}

// MARK: - F1TV Catalog Entry

struct F1TVEntry: Codable, Identifiable {
    let season: Int
    let round: Int?
    let name: String
    let type: F1TVContentType
    let duration: String?
    let url: String?

    var id: String {
        [String(season), round.map(String.init) ?? "season", type.rawValue, url ?? name].joined(separator: "-")
    }
}

// MARK: - F1TV Catalog

enum F1TVCatalog {
    nonisolated(unsafe) private static var raceIndexCache: [Region: [String: [F1TVEntry]]] = [:]
    nonisolated(unsafe) private static var seasonReviewCache: [Region: [Int: F1TVEntry]] = [:]

    static func content(for race: Race, region: Region) -> [F1TVEntry] {
        let roundEntries = raceIndex(for: region)[catalogKey(season: race.season, round: race.round)] ?? []
        if roundEntries.isEmpty, let seasonReview = seasonReview(for: race.season, region: region) {
            return [seasonReview]
        }
        return roundEntries
    }

    static func isAvailable(_ race: Race, region: Region) -> Bool {
        !content(for: race, region: region).isEmpty
    }

    static func playableLinks(for race: Race, region: Region) -> [F1TVEntry] {
        content(for: race, region: region).filter { entry in
            guard let urlString = entry.url else { return false }
            return URL(string: urlString) != nil
        }
    }

    static func hasPlayableLinks(for race: Race, region: Region) -> Bool {
        !playableLinks(for: race, region: region).isEmpty
    }

    static func seasonReview(for season: Int, region: Region) -> F1TVEntry? {
        loadSeasonReviews(for: region)[season]
    }

    static func entries(for region: Region) -> [F1TVEntry] {
        guard let url = Bundle.main.url(forResource: region.catalogResource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([F1TVEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private static func raceIndex(for region: Region) -> [String: [F1TVEntry]] {
        if let cached = raceIndexCache[region] { return cached }
        buildIndexes(for: region)
        return raceIndexCache[region] ?? [:]
    }

    private static func loadSeasonReviews(for region: Region) -> [Int: F1TVEntry] {
        if let cached = seasonReviewCache[region] { return cached }
        buildIndexes(for: region)
        return seasonReviewCache[region] ?? [:]
    }

    private static func buildIndexes(for region: Region) {
        var raceIndex: [String: [F1TVEntry]] = [:]
        var seasonReviews: [Int: F1TVEntry] = [:]

        for entry in entries(for: region) {
            if entry.type == .seasonReview, entry.round == nil {
                seasonReviews[entry.season] = entry
                continue
            }
            guard let round = entry.round else { continue }
            let key = catalogKey(season: entry.season, round: round)
            raceIndex[key, default: []].append(entry)
        }

        raceIndexCache[region] = raceIndex.mapValues { entries in
            entries.sorted { lhs, rhs in
                if lhs.type.sortOrder != rhs.type.sortOrder {
                    return lhs.type.sortOrder < rhs.type.sortOrder
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
        seasonReviewCache[region] = seasonReviews
    }

    private static func catalogKey(season: Int, round: Int) -> String {
        "\(season)-\(round)"
    }
}

private extension F1TVContentType {
    var sortOrder: Int {
        switch self {
        case .race: 0
        case .extendedHighlights: 1
        case .highlights: 2
        case .seasonReview: 3
        }
    }
}
