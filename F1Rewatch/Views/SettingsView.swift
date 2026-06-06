import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("f1-rewatch.region") private var region: Region = .us
    @State private var showResetAlert = false
    var store: WatchStore

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    settingsSection(
                        title: "F1TV Archive Region",
                        footer: "Determines which races appear when filtering by F1TV availability."
                    ) {
                        GlassPanel(radius: 20, padding: 0, prominence: .row) {
                            VStack(spacing: 0) {
                                ForEach(Region.allCases) { r in
                                    Button {
                                        region = r
                                    } label: {
                                        HStack(spacing: 14) {
                                            Text(r.flag)
                                                .font(.title2)
                                            Text(r.displayName)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(primaryText)
                                            Spacer()
                                            if r == region {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.red)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .padding(16)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    settingsSection(footer: "This will remove all watch progress and cannot be undone.") {
                        GlassPanel(radius: 20, padding: 0, prominence: .row) {
                            Button(role: .destructive) {
                                showResetAlert = true
                            } label: {
                                Label("Clear All Watched Races", systemImage: "trash")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.red)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    GlassPanel(radius: 20, padding: 16, prominence: .row) {
                        Text("F1 Rewatch is an independent app and is not affiliated with, endorsed by, or associated with Formula 1, F1, Formula One Management, or F1TV. All trademarks belong to their respective owners.")
                            .font(.footnote)
                            .foregroundStyle(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .alert("Clear Watched Races?", isPresented: $showResetAlert) {
                Button("Clear", role: .destructive) {
                    store.resetWatched()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all your watch progress. This action cannot be undone.")
            }
        }
        .navigationTitle("Settings")
    }

    private var primaryText: Color {
        colorScheme == .light ? Color.black.opacity(0.84) : .white
    }

    private var secondaryText: Color {
        colorScheme == .light ? Color.black.opacity(0.62) : .white.opacity(0.72)
    }

    private func settingsSection<Content: View>(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)
                    .padding(.horizontal, 8)
            }

            content()

            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(secondaryText.opacity(0.85))
                    .padding(.horizontal, 8)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(store: WatchStore())
    }
}
