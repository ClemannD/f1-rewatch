# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

F1 Rewatch is a native SwiftUI iOS app for tracking watched Formula 1 World Championship races. It bundles a full race catalog, F1TV availability data, and track SVG assets inside the app target.

Primary code lives under `F1Rewatch/`:

- `F1RewatchApp.swift` is the app entry point.
- `Views/` contains SwiftUI screens and shared view components.
- `Models/` contains catalog, race, F1TV, and watch-state logic.
- `Resources/` contains bundled JSON data.
- `Assets.xcassets/Tracks/` contains circuit SVG image sets.

The Xcode project is `F1Rewatch.xcodeproj`, with a single app target and scheme named `F1Rewatch`.

## Environment

- Swift: 6.0
- Deployment target: iOS 17.0
- Xcode: 26+ expected by the README
- UI uses iOS 26 glass APIs behind `#available(iOS 26.0, *)` checks and must keep iOS 17 fallbacks.

## Common Commands

List project metadata:

```bash
xcodebuild -list -project F1Rewatch.xcodeproj
```

Build for simulator:

```bash
xcodebuild -project F1Rewatch.xcodeproj -scheme F1Rewatch -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build
```

If the named simulator is not installed, list available destinations:

```bash
xcodebuild -project F1Rewatch.xcodeproj -scheme F1Rewatch -showdestinations
```

CoreSimulator may require host permissions outside restricted sandboxes. If simulator discovery or logs fail with permission or XPC errors, report that clearly instead of treating it as an app failure.

## Coding Guidelines

- Follow the existing small-file SwiftUI style: local computed properties, private helper views, and focused model types.
- Keep UI work native SwiftUI. Do not introduce third-party dependencies unless explicitly requested.
- Preserve iOS 17 compatibility when using newer APIs. Existing glass UI helpers in `Views/Components.swift` are the preferred pattern for iOS 26-specific styling.
- Keep state ownership simple. `WatchStore` is `@MainActor` and owns persisted watched race IDs through `UserDefaults`.
- Avoid broad refactors while changing catalog, watch-state, or UI behavior. This app is intentionally compact.
- Prefer typed Swift models and `Codable` for resource data. Avoid ad hoc JSON string manipulation.
- Do not hand-edit generated sections of `F1Rewatch.xcodeproj/project.pbxproj` unless adding/removing files requires it.

## Data And Assets

- `F1Rewatch/Resources/Races.json` is the bundled race catalog.
- `F1Rewatch/Resources/US-f1-tv-archive-catalog.json` is the bundled F1TV regional catalog.
- Race IDs, season, round, and date fields are behavioral keys. Be careful changing them because watched state is persisted by race ID.
- Track image names in JSON should correspond to image sets under `F1Rewatch/Assets.xcassets/Tracks/`.
- When updating F1TV data, validate the upstream source first as described in the README.

## Verification

For Swift changes, run an Xcode build when practical. For UI changes, verify both:

- iOS 26 path for glass effects, if an iOS 26 simulator/runtime is available.
- iOS 17 fallback path or code compatibility, especially around availability checks.

There are currently no dedicated test targets in the project. If adding tests, keep them focused on model/catalog behavior unless the user asks for broader coverage.

## Repository Hygiene

- Check `git status --short` before editing. The worktree may contain user changes.
- Do not revert or overwrite unrelated user changes.
- Keep generated asset/catalog churn out of unrelated code changes.
- If a command fails due to sandbox or simulator permissions, include the exact class of failure in the final response.
