import Foundation

@MainActor
final class WatchStore: ObservableObject {
    @Published private(set) var watched: Set<String> = []

    private let watchedKey = "f1-rewatch.watched"
    private let legacyKey = "f1-rewatch.watchedIDs"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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

    func unwatch(_ race: Race) {
        watched.remove(race.id)
        save()
    }

    func resetWatched() {
        watched.removeAll()
        save()
    }

    var watchedCount: Int { watched.count }

    var allRaces: [Race] {
        let today = Self.isoDayFormatter.string(from: Date())

        return RaceCatalog.races
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
    }

    private static let isoDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func load() {
        // Try boolean watched set first.
        if let data = defaults.data(forKey: watchedKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            watched = decoded
            return
        }

        // Migrate from typed watch progress.
        if let data = defaults.data(forKey: watchedKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            watched = Set(decoded.keys)
            save()
            return
        }

        // Migrate from legacy Set<String> format.
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
