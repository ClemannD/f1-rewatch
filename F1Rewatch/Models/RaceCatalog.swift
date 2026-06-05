import Foundation

enum RaceCatalog {
    static let races: [Race] = {
        guard let url = Bundle.main.url(forResource: "Races", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Race].self, from: data) else {
            return fallbackRaces
        }

        return decoded
    }()

    private static let fallbackRaces: [Race] = [
        Race(id: "2025-01-australian", season: 2025, round: 1, name: "Australian Grand Prix", circuit: "Albert Park Circuit", country: "Australia", date: "2025-03-16", trackImage: nil),
        Race(id: "2025-02-chinese", season: 2025, round: 2, name: "Chinese Grand Prix", circuit: "Shanghai International Circuit", country: "China", date: "2025-03-23", trackImage: nil),
        Race(id: "2025-03-japanese", season: 2025, round: 3, name: "Japanese Grand Prix", circuit: "Suzuka Circuit", country: "Japan", date: "2025-04-06", trackImage: nil)
    ]
}
