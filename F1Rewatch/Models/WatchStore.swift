import Foundation

@MainActor
final class WatchStore: ObservableObject {
    @Published private(set) var watchedIDs: Set<String> = []

    private let watchedKey = "f1-rewatch.watchedIDs"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func isWatched(_ race: Race) -> Bool {
        watchedIDs.contains(race.id)
    }

    func toggle(_ race: Race) {
        if watchedIDs.contains(race.id) {
            watchedIDs.remove(race.id)
        } else {
            watchedIDs.insert(race.id)
        }
        saveWatched()
    }

    func resetWatched() {
        watchedIDs.removeAll()
        saveWatched()
    }

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
        if let watchedData = defaults.data(forKey: watchedKey),
           let watched = try? JSONDecoder().decode(Set<String>.self, from: watchedData) {
            watchedIDs = watched
        }
    }

    private func saveWatched() {
        if let data = try? JSONEncoder().encode(watchedIDs) {
            defaults.set(data, forKey: watchedKey)
        }
    }

}
