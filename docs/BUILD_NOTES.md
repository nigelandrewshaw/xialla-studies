# Build notes (no Mac in CI/cloud agent)

## Environment

The scaffolding agent ran on Linux without Xcode / `xcodebuild` / iOS Simulator. Therefore:

- Sources, `project.yml`, and `XiallaStudies.xcodeproj` were generated here.
- **Compile and UI tests must run on a Mac** with Xcode 16+.
- ResearchKit is **not** vendored in this commit (large + git-lfs). Use `scripts/bootstrap-researchkit.sh` on a Mac.

## Verify on Mac

```bash
git pull
open XiallaStudies.xcodeproj
# Set Team for signing, Run on simulator/device

# Optional ResearchKit:
./scripts/bootstrap-researchkit.sh
# Then embed ResearchKit + ResearchKitUI (README)
```

## Unit tests / simulator without ResearchKit

`XiallaStudiesTests` covers config/timepoints, arm gating, `site_code`/`study_code` meta, IIEF-5 bands, snapshot Codable round-trip (incl. preferences). These do not require ResearchKit.

The app target does **not** link ResearchKit by default. Presenters use `#if canImport(ResearchKit)` with a branded SwiftUI fallback (IIEF-5 **sliders 1–5, default 3**), so a simulator build should compile and demo the full flow without ResearchKit. After bootstrap + embed, real `ORKOrderedTask`s activate.

## Local persistence

`LocalStudyStore` writes `Application Support/XiallaStudies/study-snapshot.json` (atomic). Snapshot includes enrollment, consent, survey answers/scores, reminders, kit stub, consent PDF path, and `StudyPreferences` (splash seen, demo week‑4 flag, resume route, reminder toggle). Quit mid-flow and relaunch — progress restores.

## Branding / Fieldwork

- Logo + homepage hero pulled from xialla.com CDN into `Assets.xcassets`.
- **Fieldwork** is Adobe Fonts (Typekit kit `shw7daa`) — webfont license does **not** allow shipping binaries in the app. See `XiallaStudies/Resources/Fonts/README.md`. Until a desktop license is added, UI uses **Avenir Next** at Fieldwork-like weights. `UIAppFonts` can be registered when `.otf` files are dropped in.
- Official Pantone swatch in `BrandTheme`: ink `#212322` (419 C), tan surfaces `#CDA788` (4665 C), accent `#FF6A39` (1645 C). Forest/sage in kit but not chrome.

## Study parameters / provider

`StudyParameters` + `StudyProviderParameters` hold study/site codes, follow-ups, and the participating investigator (Jeff hardcoded for demo). Screens read `StudyConfig.active` / `StudyConfig.provider` so a future DB load can swap the pack without rewriting UI.

## Asset catalog path

`Assets.xcassets` must resolve to `XiallaStudies/Resources/Assets.xcassets`. Regenerate with `python3 scripts/generate_xcodeproj.py` if needed.

## Regenerating the Xcode project

```bash
python3 scripts/generate_xcodeproj.py
# or
xcodegen generate
```
