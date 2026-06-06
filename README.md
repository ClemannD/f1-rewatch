# F1 Rewatch 🏎️

An iOS app for tracking your progress rewatching every Formula 1 World Championship race — from the 1950 British Grand Prix at Silverstone to today.

## Features

- **Complete race catalog** — 1,171 races across 76 seasons (1950–2026)
- **Track outlines** — Every race shows the correct circuit layout for that era, with 159 unique track variations
- **Watch tracking** — Mark races as watched and track your overall progress
- **Season filtering** — Browse by season or search by race name, circuit, or country
- **Glass UI** — Built for iOS 26 with glass effects and the new automatic app icon system

## Screenshots

*Coming soon*

## Requirements

- iOS 26.0+
- Xcode 26+

## F1TV Catalog

The app bundles F1TV availability data from the [f1-archive-catalog](https://github.com/) repo.

### Updating the catalog

When the regional catalog is updated:

```bash
cp /path/to/f1-archive-catalog/regions/us.json F1Rewatch/Resources/F1TVCatalog.json
```

Then rebuild the app. Validate the source file first:

```bash
cd /path/to/f1-archive-catalog
python3 scripts/validate.py regions/us.json
```

Each entry links to F1TV content by `season` + `round` + `type`. Long-press a race to open available F1TV links (full race, extended highlights, highlights).

## Acknowledgments

Track circuit SVGs are from [**julesr0y/f1-circuits-svg**](https://github.com/julesr0y/f1-circuits-svg) — a fantastic open-source collection of all Formula 1 circuit layouts and their evolutions from 1950 to the present day. Huge thanks to Jules Roy for creating and maintaining this resource. The SVGs are used under the [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) license.

## Disclaimer

F1 Rewatch is an independent fan project. It is **not** affiliated with, endorsed by, or sponsored by Formula 1, Formula One Management, Liberty Media, or F1TV.

All Formula 1 trademarks, race names, logos, and video content are the property of their respective owners. This app does not host, stream, or distribute any race footage. F1TV links open content on [F1TV](https://f1tv.formula1.com) and require an active subscription in your region.

Race calendar and circuit data are compiled from public sources for personal tracking only. F1TV availability data comes from the community [f1-archive-catalog](https://github.com/) project and may be incomplete or outdated.

## License

MIT License — see [LICENSE](LICENSE).
