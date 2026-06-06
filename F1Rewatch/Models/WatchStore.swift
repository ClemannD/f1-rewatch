import Foundation
import Observation

@MainActor
@Observable
final class WatchStore {
    private(set) var watched: Set<String> = []

    let allRaces: [Race]
    let racesBySeason: [Int: [Race]]

    private let watchedKey = "f1-rewatch.watched"
    private let legacyKey = "f1-rewatch.watchedIDs"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let today = Self.isoDayFormatter.string(from: Date())
        let races = RaceCatalog.races
            .filter { $0.date <= today }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date {
                    return lhs.date > rhs.date
                }
                if lhs.season != rhs.season {
                    return lhs.season > rhs.season
                }
                return lhs.round > rhs.round
            }

        allRaces = races
        racesBySeason = Dictionary(grouping: races, by: \.season)

        load()
    }

    func isWatched(_ race: Race) -> Bool {
        watched.contains(race.id)
    }

    func toggle(_ race: Race) {
        if watched.contains(race.id) {
            watched.remove(race.id)
        } else {
            watched.insert(race.id)
        }
        save()
    }

    func markWatched(_ races: [Race]) {
        watched.formUnion(races.map(\.id))
        save()
    }

    func resetWatched() {
        watched.removeAll()
        save()
    }

    private static let isoDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func load() {
        if let data = defaults.data(forKey: watchedKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            watched = decoded
            return
        }

        if let data = defaults.data(forKey: watchedKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            watched = Set(decoded.keys)
            save()
            return
        }

        if let legacyData = defaults.data(forKey: legacyKey),
           let legacyIDs = try? JSONDecoder().decode(Set<String>.self, from: legacyData) {
            watched = legacyIDs
            save()
            defaults.removeObject(forKey: legacyKey)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(watched) {
            defaults.set(data, forKey: watchedKey)
        }
    }
}
