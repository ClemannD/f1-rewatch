# Examples

## Full-width gesture row (recommended for cards)

```swift
struct RaceListView: View {
    let races: [Race]
    let onToggle: (Race) -> Void

    private let rowShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(races) { race in
                RaceRow(race: race, isWatched: race.isWatched)
        .contentShape(.interaction, rowShape)
        .contentShape(.contextMenuPreview, rowShape)
        .pressFeedback { onToggle(race) }
        .contextMenu {
                        Button("Mark unwatched", role: .destructive) { onToggle(race) }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("\(race.name), \(race.circuit)")
                    .accessibilityHint(race.isWatched ? "Mark unwatched" : "Mark watched")
            }
        }
    }
}

private struct RaceRow: View {
    let race: Race
    let isWatched: Bool

    var body: some View {
        HStack(spacing: 12) {
            statusBadge
            VStack(alignment: .leading, spacing: 4) {
                Text(race.name).font(.headline)
                Text(race.circuit).font(.subheadline)
            }
            Spacer(minLength: 8)
            trackIcon
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanelSurface(radius: 20)  // interactive: false (default)
    }
}
```

## Compact button row (chips, pills)

```swift
struct SeasonChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var onMarkAll: (() -> Void)?

    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(isSelected ? .red : .white.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onMarkAll {
                Button("Mark all as watched", action: onMarkAll)
            }
        }
        .accessibilityLabel("\(title) season")
    }
}
```

## Extracting a reusable wrapper

When many rows share the same interaction stack:

```swift
struct TapContextRow<Content: View, Menu: View>: View {
    var cornerRadius: CGFloat = 20
    var onTap: () -> Void
    @ViewBuilder var content: () -> Content
    @ViewBuilder var menu: () -> Menu

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content()
        .contentShape(.interaction, shape)
        .contentShape(.contextMenuPreview, shape)
        .pressFeedback(onTap: onTap)
        .contextMenu { menu() }
    }
}

// Usage
TapContextRow(onTap: { toggle(item) }) {
    ItemRow(item: item)
} menu: {
    Button("Delete", role: .destructive) { delete(item) }
}
.accessibilityLabel(item.name)
```

Keep accessibility on the call site so labels stay domain-specific.

## Anti-pattern (avoid)

```swift
// Broken: long press won't work; dead tap zones likely
Button { toggle(item) } label: {
    ItemRow(item: item)  // no frame(maxWidth: .infinity)
}
.buttonStyle(.plain)
.contextMenu { ... }
```

```swift
// Broken: double animation on long press
ItemRow(item: item)
    .glassPanelSurface(interactive: true)
    .contextMenu { ... }
```
