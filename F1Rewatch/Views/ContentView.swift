import SwiftUI

enum WatchFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unwatched = "Next"
    case watched = "Watched"

    var id: String { rawValue }
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var store = WatchStore()
    @State private var selectedSeason: Int?
    @State private var filter: WatchFilter = .all
    @State private var searchText = ""

    private var seasons: [Int] {
        Array(Set(store.allRaces.map(\.season))).sorted(by: >)
    }

    private var filteredRaces: [Race] {
        store.allRaces.filter { race in
            let seasonMatches = selectedSeason == nil || race.season == selectedSeason
            let watchMatches: Bool
            switch filter {
            case .all:
                watchMatches = true
            case .unwatched:
                watchMatches = !store.isWatched(race)
            case .watched:
                watchMatches = store.isWatched(race)
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatches = query.isEmpty ||
                race.name.localizedCaseInsensitiveContains(query) ||
                race.circuit.localizedCaseInsensitiveContains(query) ||
                race.country.localizedCaseInsensitiveContains(query)

            return seasonMatches && watchMatches && searchMatches
        }
    }

    private var watchedCount: Int {
        store.allRaces.filter(store.isWatched).count
    }

    private var progress: Double {
        guard !store.allRaces.isEmpty else { return 0 }
        return Double(watchedCount) / Double(store.allRaces.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    LazyVStack(spacing: 14, pinnedViews: []) {
                        header
                            .padding(.horizontal, 16)
                        seasonPicker
                        raceList
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("F1 Rewatch")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Clear watched races", role: .destructive) {
                            store.resetWatched()
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis")
                    }
                    .compactGlassButton()
                }
            }
            .searchable(text: $searchText, prompt: "Race, circuit, country")
        }
        .tint(.red)
    }

    private var header: some View {
        GlassPanel {
            HStack(spacing: 16) {
                ProgressRing(progress: progress)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Watched \(watchedCount) of \(store.allRaces.count)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(headerPrimaryText)

                    if let nextRace = store.allRaces.first(where: { !store.isWatched($0) }) {
                        Text("Next up: \(String(nextRace.season)) \(nextRace.shortName)")
                            .font(.subheadline)
                            .foregroundStyle(headerSecondaryText)
                            .lineLimit(2)
                    } else {
                        Text("Archive complete")
                            .font(.subheadline)
                            .foregroundStyle(headerSecondaryText)
                    }

                    Picker("Filter", selection: $filter) {
                        ForEach(WatchFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var headerPrimaryText: Color {
        colorScheme == .light ? Color.black.opacity(0.84) : .white
    }

    private var headerSecondaryText: Color {
        colorScheme == .light ? Color.black.opacity(0.62) : .white.opacity(0.74)
    }

    private var seasonPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                SeasonChip(title: "All", isSelected: selectedSeason == nil) {
                    selectedSeason = nil
                }

                ForEach(seasons, id: \.self) { season in
                    SeasonChip(title: String(season), isSelected: selectedSeason == season) {
                        selectedSeason = season
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity)
    }

    private var raceList: some View {
        LazyVStack(spacing: 10) {
            ForEach(filteredRaces) { race in
                RaceRow(race: race, isWatched: store.isWatched(race)) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        store.toggle(race)
                    }
                }
            }
        }
    }
}

private struct SeasonChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.78))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    Capsule()
                        .fill(isSelected ? .red.opacity(0.80) : .white.opacity(0.10))
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct RaceRow: View {
    let race: Race
    let isWatched: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            GlassPanel(radius: 20, padding: 14, prominence: .row) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isWatched ? .green.opacity(0.92) : .white.opacity(0.18))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Circle()
                                    .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                            }

                        Image(systemName: isWatched ? "checkmark" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(String(race.season))
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(Color(red: 1.0, green: 0.32, blue: 0.35))

                            Text("Round \(race.round)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.78))
                        }

                        Text(race.shortName)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text("\(race.circuit) · \(race.country)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    if let trackImage = race.trackImage {
                        Image("Tracks/\(trackImage)")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white.opacity(0.30))
                            .frame(width: 48, height: 48)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
