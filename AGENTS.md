# AGENTS.md

## Project

F1 Rewatch is a native iOS app for tracking watched Formula 1 World Championship races. The app bundles its race catalog, F1TV archive availability data, and track SVG assets locally.

## Tech

- Swift 6
- SwiftUI
- iOS 26.0 deployment target
- Xcode 26+
- Single app target and scheme: `F1Rewatch`

## Layout

- `F1Rewatch/F1RewatchApp.swift`: app entry point
- `F1Rewatch/Views/`: SwiftUI screens and shared view components
- `F1Rewatch/Models/`: catalog, race, F1TV, and watch-state logic
- `F1Rewatch/Resources/`: bundled JSON catalog data
- `F1Rewatch/Assets.xcassets/Tracks/`: circuit SVG image sets

## Notes

- Keep UI native SwiftUI and follow the existing compact file style.
- Watch state is persisted by race ID, so treat race IDs as stable behavioral keys.
- Build with `xcodebuild -project F1Rewatch.xcodeproj -scheme F1Rewatch -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build` when practical.
