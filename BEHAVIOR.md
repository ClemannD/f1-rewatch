# F1 Rewatch — App Behavior

This document describes what the app does from a user’s perspective: screens, gestures, filters, persistence, and edge cases. It reflects the current implementation.

---

## Overview

F1 Rewatch is a single-screen iOS app (plus Settings) for tracking which Formula 1 World Championship races you have watched. All race data, F1TV archive metadata, and track artwork are bundled locally — no network is required except when opening an F1TV link in Safari or the F1TV app.

**What is tracked:** watched / unwatched state per race, keyed by stable race ID (e.g. `1950-01-british-grand-prix`).

**What is not tracked:** partial progress, watch dates, notes, or sync across devices.

---

## Data scope

### Race catalog

- Loaded from bundled `Races.json` (~1,171 races, seasons 1950–2026).
- **Only races on or before today’s date are shown.** Future scheduled races are excluded at load time (comparison uses `yyyy-MM-dd` in the device’s local calendar).
- Races are sorted **newest first** (by date, then season, then round).
- Each race has: season, round, full name, circuit, country, date, and optional track image asset.
- Display names shorten `"Grand Prix"` to `"GP"` (e.g. `"Monaco GP"`).

### F1TV catalog

- Loaded from bundled regional JSON (currently **United States** only: `US-f1-tv-archive-catalog.json`).
- Entries are matched to races by `season` + `round`.
- Content types: Full Race, Extended Highlights, Highlights, Season Recap.
- If a race has no round-specific entries but a **season recap** exists for that season, the race is still considered F1TV-available (recap is used as fallback content).
- A race shows the red TV icon and context-menu links only when at least one entry has a **valid URL**.

### Track images

- When present, the circuit outline appears on the right side of each race row (template rendering, muted white).
- Image set name comes from `trackImage` in the catalog (e.g. `Tracks/silverstone-1`).

---

## Main screen (`ContentView`)

### Layout (top to bottom)

1. **Navigation bar** — inline large title `"F1 Rewatch"`, red accent tint.
2. **Search field** — system searchable bar; prompt: `"Race, circuit, country"`.
3. **Progress header** — glass panel with progress ring, stats, filter picker.
4. **Season chips** — horizontal scroll of year filters.
5. **Race list** — scrollable cards, one per race.

Background is a dark gradient with a subtle angular color wash. Scroll indicators are hidden.

### Progress header

| Element | Behavior |
|--------|----------|
| **Progress ring** | Shows `watched ÷ visible races` as a percentage for the **current filter stack** (filter + season + search). Empty set → 0%. |
| **"Watched X of Y"** | Same counts as the ring. |
| **"Next up: …"** | First **unwatched** race in the current filtered list. Because the list is newest-first, this is the **most recent unwatched** race in view — not necessarily the chronologically next race if you are rewatching from 1950. |
| **"Archive complete"** | Shown when every race in the current filtered list is watched (and the list is non-empty). |
| **All / F1TV segmented control** | Switches the archive filter (see below). |

### Archive filter (`All` vs `F1TV`)

| Mode | Races shown |
|------|-------------|
| **All** | Every race in the catalog that has occurred (date ≤ today). |
| **F1TV** | Subset of those races that have at least one F1TV catalog entry for the **selected region** (Settings). |

When switching to F1TV, if the currently selected season has **no** F1TV-available races, the season selection is **cleared** automatically.

Progress, season chips, and the race list all respect the active filter.

### Search

- Trims leading/trailing whitespace.
- Case-insensitive match on **race name**, **circuit**, or **country**.
- Combines with season chip and All/F1TV filter.
- Non-empty search with no matches → standard iOS **search empty state** (`ContentUnavailableView.search`).

### Season chips

Horizontal scroll of capsule buttons:

| Chip | Tap | Long press (context menu) |
|------|-----|---------------------------|
| **All** | Clears season filter; shows all races (within All/F1TV filter). | No menu. |
| **Year (e.g. 2024)** | Filters list to that season only. | **"Mark all as watched"** — marks every race in that season as watched (with spring animation). |

**Season chip details:**

- Years are derived from races **after** the All/F1TV filter, sorted **descending** (newest year leftmost after "All").
- Selected chip: red-tinted fill, brighter text.
- Unselected: translucent white fill.
- **Checkmark on a year chip** when **every** race in that season (respecting F1TV filter) is watched.
- Long-press **"Mark all as watched"** only appears on year chips that have at least one race. It marks the same set used for the checkmark (all races in that season, or only F1TV-available races when F1TV filter is on).
- Long-press does **not** offer "mark all unwatched" or toggle.

### Race list rows

Each row is a glass card showing:

- **Watch badge** (left): green circle + checkmark if watched; gray circle + play icon if unwatched.
- **Season** (red caption), **round**, optional **TV icon** (red, when F1TV links exist).
- **Short race name** (headline).
- **Circuit · country** (subtitle).
- **Track outline** (right), when available.

**Tap row** → toggles watched/unwatched with a spring animation.

**Long press row** → context menu:

1. **"Watch on F1 TV"** section (only if playable links exist):
   - One button per link, labeled by content type.
   - Duration appended when known (e.g. `"Full Race (2hr 14min)"`, `"Highlights (8min)"`).
   - Tapping opens the URL via the system (`openURL`) — typically Safari or F1TV.
   - Link order: Full Race → Extended Highlights → Highlights → Season Recap.
2. **"Mark unwatched"** (destructive, only when race is already watched).

There is **no** context-menu item to mark watched; use tap for that.

**Accessibility:** Row is a single combined element, button trait, hint reflects toggle direction, value is Watched/Unwatched.

### Empty states

| Condition | Message |
|-----------|---------|
| Search with no results | Standard search empty UI. |
| F1TV filter, no matches | "No F1TV Races" — none available in your region for this view. |
| Season selected, no races | "No Races" for that season. |
| Otherwise empty catalog | "No Races" — nothing to track. |

---

## Settings (`SettingsView`)

Reached via the **gear** toolbar button (glass-styled on iOS 26).

### F1TV Archive Region

- Section title: **"F1TV Archive Region"**.
- Footer: *"Determines which races appear when filtering by F1TV availability."*
- Currently one option: **United States** (🇺🇸).
- Tap a region to select it; checkmark on the active row.
- Stored in `@AppStorage("f1-rewatch.region")` and persists across launches.
- Changing region affects F1TV filter, TV icons, and context-menu links immediately (same `WatchStore` instance is passed from the main screen).

### Clear All Watched Races

- Destructive button: **"Clear All Watched Races"**.
- Shows confirmation alert: **"Clear Watched Races?"** with message that progress cannot be undone.
- **Clear** → removes all watched state and saves.
- **Cancel** → dismisses with no change.

### Disclaimer

Static footnote: independent app, not affiliated with Formula 1 / F1TV.

---

## Watch state & persistence

### Operations

| Action | Effect |
|--------|--------|
| Tap race row | Toggle watched for that race ID. |
| Long press season chip → Mark all as watched | Add all races in that season (filter-aware) to watched set. |
| Long press race → Mark unwatched | Remove that race from watched set. |
| Settings → Clear All Watched Races | Empty entire watched set. |

`markWatched` is additive only — it never unmarks races.

### Storage

- **Key:** `f1-rewatch.watched` in `UserDefaults`.
- **Format:** JSON-encoded `Set<String>` of race IDs.
- **Migration:** On first load, migrates from legacy `f1-rewatch.watchedIDs` or an older dictionary format, then re-saves in the new format.

Watch state is **local to the device**; no iCloud or export.

---

## Visual & platform behavior

- **Deployment target:** iOS 26.0.
- **Glass effects:** Panels and interactive rows use Liquid Glass on iOS 26; fallback material + stroke on older APIs (modifier guards with `#available`).
- **Color scheme:** Header progress text and ring colors adapt to light/dark mode.
- **Dynamic Type:** Progress ring and race row badge/track sizes scale with `@ScaledMetric`.
- **Animations:** Watch toggles and bulk mark use `.spring(response: 0.28, dampingFraction: 0.82)`.

---

## Interaction matrix (quick reference)

| Gesture / control | Target | Result |
|-------------------|--------|--------|
| Tap | Race row | Toggle watched |
| Long press | Race row | Menu: F1TV links + Mark unwatched (if watched) |
| Tap | Season year chip | Filter to that season |
| Long press | Season year chip | Mark all races in season as watched |
| Tap | "All" season chip | Clear season filter |
| Tap | All / F1TV segment | Change archive filter |
| Type | Search field | Filter by name, circuit, country |
| Tap | Settings gear | Open Settings |
| Tap | Region row | Set F1TV region |
| Tap | Clear All Watched | Confirm → reset all progress |

---

## Behaviors that are intentionally *not* implemented

- No swipe actions on rows.
- No "mark all unwatched" for a season.
- No mark-watched in race context menu (tap only).
- No undo after clear-all.
- No in-app video playback.
- No account or F1TV subscription handling.
- No automatic mark-watched when opening F1TV.
- No multi-region catalogs beyond what is bundled per `Region` case.

---

## Related files

| Concern | Location |
|---------|----------|
| Main UI & interactions | `F1Rewatch/Views/ContentView.swift` |
| Settings | `F1Rewatch/Views/SettingsView.swift` |
| Shared UI (background, glass, progress ring) | `F1Rewatch/Views/Components.swift` |
| Watch state | `F1Rewatch/Models/WatchStore.swift` |
| Race model | `F1Rewatch/Models/Race.swift` |
| Race catalog load | `F1Rewatch/Models/RaceCatalog.swift` |
| F1TV matching & links | `F1Rewatch/Models/F1TVCatalog.swift` |
| Race data | `F1Rewatch/Resources/Races.json` |
| F1TV data (US) | `F1Rewatch/Resources/US-f1-tv-archive-catalog.json` |
