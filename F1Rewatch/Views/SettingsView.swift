import SwiftUI

struct SettingsView: View {
    @AppStorage("f1-rewatch.region") private var region: Region = .us
    @State private var showResetAlert = false
    var store: WatchStore

    var body: some View {
        ZStack {
            AppBackground()

            Form {
                Section {
                    Picker("Region", selection: $region) {
                        ForEach(Region.allCases) { r in
                            Label {
                                Text(r.displayName)
                            } icon: {
                                Text(r.flag)
                            }
                            .tag(r)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("F1TV Archive Region")
                } footer: {
                    Text("Determines which races appear when filtering by F1TV availability.")
                }

                Section {
                    Button("Clear All Watched Races", role: .destructive) {
                        showResetAlert = true
                    }
                } footer: {
                    Text("This will remove all watch progress and cannot be undone.")
                }

                Section {
                } footer: {
                    Text("F1 Rewatch is an independent app and is not affiliated with, endorsed by, or associated with Formula 1, F1, Formula One Management, or F1TV. All trademarks belong to their respective owners.")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .preferredColorScheme(.dark)
        .alert("Clear Watched Races?", isPresented: $showResetAlert) {
            Button("Clear", role: .destructive) {
                store.resetWatched()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all your watch progress. This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(store: WatchStore())
    }
}
