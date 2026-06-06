import Foundation

struct Race: Identifiable, Codable, Hashable {
    let id: String
    let season: Int
    let round: Int
    let name: String
    let circuit: String
    let country: String
    let date: String
    let trackImage: String?

    var shortName: String {
        name.replacingOccurrences(of: "Grand Prix", with: "GP")
    }
}
