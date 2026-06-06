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
    @State private var store = WatchStore()
    @State private var selectedSeason: Int?
    @State private var filter: WatchFilter = .all
    @State private var searchText = ""

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
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
        filterScopedRaces.filter { race in
            let seasonMatches = selectedSeason == nil || race.season == selectedSeason
            let searchMatches = trimmedSearch.isEmpty ||
                race.name.localizedCaseInsensitiveContains(trimmedSearch) ||
                race.circuit.localizedCaseInsensitiveContains(trimmedSearch) ||
                race.country.localizedCaseInsensitiveContains(trimmedSearch)

            return seasonMatches && searchMatches
        }
    }

    private var seasons: [Int] {
        Array(Set(filterScopedRaces.map(\.season))).sorted(by: >)
    }

    private var watchedCount: Int {
        filteredRaces.filter(store.isWatched).count
    }

    private var progressTotal: Int {
        filteredRaces.count
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
                    Menu {
                        NavigationLink {
                            SettingsView(store: store)
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .accessibilityLabel("More")
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

                    if let nextRace = filteredRaces.first(where: { !store.isWatched($0) }) {
                        Text("Next up: \(String(nextRace.season)) \(nextRace.shortName)")
                            .font(.subheadline)
                            .foregroundStyle(headerSecondaryText)
                            .lineLimit(2)
                    } else if progressTotal > 0 {
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

    private func seasonRaces(for season: Int) -> [Race] {
        let races = store.racesBySeason[season] ?? []
        guard filter == .f1tv else { return races }
        return races.filter { F1TVCatalog.isAvailable($0, region: region) }
    }

    private func toggleRace(_ race: Race) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            store.toggle(race)
        }
    }

    private func raceRowAccessibilityLabel(for race: Race) -> String {
        "\(race.season) \(race.shortName), round \(race.round), \(race.circuit), \(race.country)"
    }

    @ViewBuilder
    private func raceContextMenu(for race: Race) -> some View {
        let f1tvLinks = F1TVCatalog.playableLinks(for: race, region: region)

        if !f1tvLinks.isEmpty {
            Section("Watch on F1 TV") {
                ForEach(f1tvLinks) { entry in
                    Button {
                        if let urlString = entry.url, let url = URL(string: urlString) {
                            openURL(url)
                        }
                    } label: {
                        Label(entry.menuLabel, systemImage: entry.type.systemImage)
                    }
                }
            }
        }

        if store.isWatched(race) {
            Button(role: .destructive) {
                toggleRace(race)
            } label: {
                Label("Mark unwatched", systemImage: "xmark")
            }
        }
    }

    private var seasonPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                SeasonChip(
                    title: "All",
                    accessibilityLabel: "All seasons",
                    isSelected: selectedSeason == nil,
                    isComplete: false
                ) {
                    selectedSeason = nil
                }

                ForEach(seasons, id: \.self) { season in
                    let races = seasonRaces(for: season)

                    SeasonChip(
                        title: String(season),
                        accessibilityLabel: "\(season) season",
                        isSelected: selectedSeason == season,
                        isComplete: !races.isEmpty && races.allSatisfy(store.isWatched),
                        markAllWatched: races.isEmpty ? nil : {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                store.markWatched(races)
                            }
                        },
                        action: {
                            selectedSeason = season
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var raceList: some View {
        if filteredRaces.isEmpty {
            emptyState
                .padding(.top, 32)
        } else {
            LazyVStack(spacing: 10) {
                ForEach(filteredRaces) { race in
                    RaceRow(
                        race: race,
                        isWatched: store.isWatched(race),
                        hasPlayableF1TV: F1TVCatalog.hasPlayableLinks(for: race, region: region)
                    )
                    .contentShape(.interaction, RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .pressFeedback {
                        toggleRace(race)
                    }
                    .contextMenu {
                        raceContextMenu(for: race)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(raceRowAccessibilityLabel(for: race))
                    .accessibilityHint(store.isWatched(race) ? "Mark unwatched" : "Mark watched")
                    .accessibilityValue(store.isWatched(race) ? "Watched" : "Unwatched")
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !trimmedSearch.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if filter == .f1tv {
            ContentUnavailableView(
                "No F1TV Races",
                systemImage: "tv.slash",
                description: Text("No races in this view are available on F1 TV for your region.")
            )
        } else if let selectedSeason {
            ContentUnavailableView(
                "No Races",
                systemImage: "flag.checkered",
                description: Text("No races found for the \(selectedSeason) season.")
            )
        } else {
            ContentUnavailableView(
                "No Races",
                systemImage: "flag.checkered",
                description: Text("No races are available to track yet.")
            )
        }
    }
}

private struct SeasonChip: View {
    let title: String
    let accessibilityLabel: String
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
                        .accessibilityHidden(true)
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
        .accessibilityLabel(accessibilityLabel)
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
    let hasPlayableF1TV: Bool

    @ScaledMetric(relativeTo: .headline) private var badgeSize = 32.0
    @ScaledMetric(relativeTo: .headline) private var trackSize = 48.0

    var body: some View {
        rowContent
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassPanelSurface(radius: 20, prominence: .row)
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            watchBadge

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(String(race.season))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.32, blue: 0.35))

                    Text("Round \(race.round)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))

                    if hasPlayableF1TV {
                        Image(systemName: "tv.fill")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.9))
                            .accessibilityHidden(true)
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
                    .frame(width: trackSize, height: trackSize)
                    .accessibilityHidden(true)
            }
        }
    }

    private var watchBadge: some View {
        ZStack {
            Circle()
                .fill(watchBadgeColor)
                .frame(width: badgeSize, height: badgeSize)

            Image(systemName: isWatched ? "checkmark" : "play.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
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
