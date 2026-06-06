import SwiftUI

enum WatchFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case f1tv = "F1TV"

    var id: String { rawValue }
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @AppStorage("f1-rewatch.region") private var region: Region = .us
    @StateObject private var store = WatchStore()
    @State private var selectedSeason: Int?
    @State private var filter: WatchFilter = .all
    @State private var searchText = ""

    private var seasons: [Int] {
        Array(Set(filterScopedRaces.map(\.season))).sorted(by: >)
    }

    private var filterScopedRaces: [Race] {
        switch filter {
        case .all:
            store.allRaces
        case .f1tv:
            store.allRaces.filter { F1TVCatalog.isAvailable($0, region: region) }
        }
    }

    private var filteredRaces: [Race] {
        store.allRaces.filter { race in
            let seasonMatches = selectedSeason == nil || race.season == selectedSeason
            let filterMatches: Bool
            switch filter {
            case .all:
                filterMatches = true
            case .f1tv:
                filterMatches = F1TVCatalog.isAvailable(race, region: region)
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatches = query.isEmpty ||
                race.name.localizedCaseInsensitiveContains(query) ||
                race.circuit.localizedCaseInsensitiveContains(query) ||
                race.country.localizedCaseInsensitiveContains(query)

            return seasonMatches && filterMatches && searchMatches
        }
    }

    private var watchedCount: Int {
        filterScopedRaces.filter(store.isWatched).count
    }

    private var progressTotal: Int {
        filterScopedRaces.count
    }

    private var progress: Double {
        guard progressTotal > 0 else { return 0 }
        return Double(watchedCount) / Double(progressTotal)
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
                    NavigationLink {
                        SettingsView(onResetWatched: { store.resetWatched() })
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .compactGlassButton()
                }
            }
            .searchable(text: $searchText, prompt: "Race, circuit, country")
            .onChange(of: filter) {
                if let selected = selectedSeason, !seasons.contains(selected) {
                    selectedSeason = nil
                }
            }
        }
        .tint(.red)
    }

    private var header: some View {
        GlassPanel {
            HStack(spacing: 16) {
                ProgressRing(progress: progress)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Watched \(watchedCount) of \(progressTotal)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(headerPrimaryText)

                    if let nextRace = filterScopedRaces.first(where: { !store.isWatched($0) }) {
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
                SeasonChip(title: "All", isSelected: selectedSeason == nil, isComplete: false) {
                    selectedSeason = nil
                }

                ForEach(seasons, id: \.self) { season in
                    let seasonRaces = store.allRaces.filter { $0.season == season }

                    SeasonChip(
                        title: String(season),
                        isSelected: selectedSeason == season,
                        isComplete: !seasonRaces.isEmpty && seasonRaces.allSatisfy(store.isWatched),
                        markAllWatched: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                store.markWatched(seasonRaces)
                            }
                        },
                        action: {
                            selectedSeason = season
                        }
                    )
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
                RaceRow(
                    race: race,
                    isWatched: store.isWatched(race),
                    f1tvContent: F1TVCatalog.content(for: race, region: region),
                    toggle: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            store.toggle(race)
                        }
                    },
                    openF1TV: { url in
                        openURL(url)
                    }
                )
            }
        }
    }
}

private struct SeasonChip: View {
    let title: String
    let isSelected: Bool
    let isComplete: Bool
    var markAllWatched: (() -> Void)?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                }

                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
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
        .contextMenu {
            if let markAllWatched {
                Button(action: markAllWatched) {
                    Label("Mark all as watched", systemImage: "checkmark.circle")
                }
            }
        }
    }
}

private struct RaceRow: View {
    let race: Race
    let isWatched: Bool
    let f1tvContent: [F1TVEntry]
    let toggle: () -> Void
    let openF1TV: (URL) -> Void

    private var f1tvLinks: [F1TVEntry] {
        f1tvContent.filter { entry in
            guard let urlString = entry.url else { return false }
            return URL(string: urlString) != nil
        }
    }

    var body: some View {
        Button(action: toggle) {
            GlassPanel(radius: 20, padding: 14, prominence: .row, interactive: true) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(watchBadgeColor)
                            .frame(width: 32, height: 32)

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

                            if !f1tvContent.isEmpty {
                                Image(systemName: "tv.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red.opacity(0.9))
                            }
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
        .contextMenu {
            if !f1tvLinks.isEmpty {
                Section("Watch on F1 TV") {
                    ForEach(f1tvLinks) { entry in
                        Button {
                            if let urlString = entry.url, let url = URL(string: urlString) {
                                openF1TV(url)
                            }
                        } label: {
                            Label(entry.menuLabel, systemImage: entry.type.systemImage)
                        }
                    }
                }
            }

            if isWatched {
                Button(role: .destructive) {
                    toggle()
                } label: {
                    Label("Mark unwatched", systemImage: "xmark")
                }
            }
        }
    }

    private var watchBadgeColor: Color {
        isWatched ? .green.opacity(0.92) : .white.opacity(0.18)
    }
}

private extension F1TVEntry {
    var menuLabel: String {
        if let durationText {
            "\(type.label) (\(durationText))"
        } else {
            type.label
        }
    }

    var durationText: String? {
        guard let duration, !duration.isEmpty else { return nil }
        let parts = duration.split(separator: ":").compactMap { Int($0) }

        let totalMinutes: Int
        switch parts.count {
        case 3:
            totalMinutes = parts[0] * 60 + parts[1]
        case 2:
            totalMinutes = parts[0]
        default:
            return nil
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0, minutes > 0 {
            return "\(hours)hr \(minutes)min"
        }
        if hours > 0 {
            return "\(hours)hr"
        }
        return "\(minutes)min"
    }
}

#Preview {
    ContentView()
}
