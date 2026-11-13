# Build notes (no Mac in CI/cloud agent)

## Environment

The scaffolding agent ran on Linux without Xcode / `xcodebuild` / iOS Simulator. Therefore:

- Sources, `project.yml`, and `XiallaStudies.xcodeproj` were generated here.
- **Compile and UI tests must run on a Mac** with Xcode 16+.
- ResearchKit is **not** committed (large + git-lfs). Bootstrap on a Mac clones it into `Vendor/` (gitignored) and wires the Xcode project.

## Mac: open, sign, run (without ResearchKit)

```bash
git pull
open XiallaStudies.xcodeproj
# Select XiallaStudies scheme → Signing & Capabilities → your Team
# Run on simulator or device
```

Branded SwiftUI consent/survey fallbacks run the full demo without ResearchKit (`#if canImport`). IIEF-5 uses **official item wording**, 1–5 sliders defaulting to **3**, with tan `#CDA788` filled tracks.

## Mac: wire ResearchKit (recommended)

```bash
# One-time (or after a clean clone):
./scripts/bootstrap-researchkit.sh

# Optional fork:
# RESEARCHKIT_URL=https://github.com/nigelandrewshaw/ResearchKit.git ./scripts/bootstrap-researchkit.sh

open XiallaStudies.xcodeproj
# Team → Build & Run
```

What bootstrap does:

1. Clones ResearchKit into `Vendor/ResearchKit/` (requires network; `brew install git-lfs` recommended).
2. Regenerates `XiallaStudies.xcodeproj` via `scripts/generate_xcodeproj.py`.
3. Runs `scripts/wire_researchkit_xcodeproj.py` to:
   - add `Vendor/ResearchKit/ResearchKit.xcodeproj` as a subproject
   - link **ResearchKit** + **ResearchKitUI**
   - **Embed & Sign** both frameworks on the app target

You should **not** need to manually Add Files / Embed in Xcode after a successful bootstrap. If frameworks are missing (e.g. you regenerated the project later):

```bash
python3 scripts/generate_xcodeproj.py
python3 scripts/wire_researchkit_xcodeproj.py
```

### XcodeGen alternative

```bash
brew install xcodegen
./scripts/bootstrap-researchkit.sh   # clone + wire checked-in pbxproj
# If you prefer regenerating from project.yml:
xcodegen generate
python3 scripts/wire_researchkit_xcodeproj.py
```

### What “wired” ResearchKit enables

| Flow | Behavior |
|------|----------|
| Consent | Instruction steps (from `ORKConsentDocument.instructionSteps`; `ORKVisualConsentStep` removed in RK 3) → comprehension form → `ORKConsentReviewStep` signature → PDF via `ORKConsentDocument.makePDF` when feasible |
| Surveys | `ORKOrderedTask` with official IIEF-5 scale items (1–5, default 3) + companion forms |
| Bookends | Branded SwiftUI intro/hub screens still wrap the ORK task sheets |
| Fallback | If frameworks are not linked, SwiftUI consent stubs + `BrandedSurveyFallbackView` keep demos working |

ORK task chrome uses the app tint (tan `#CDA788`) for scale/slider fills. Primary CTAs remain black `#212322` on white canvases.

## Unit tests

`XiallaStudiesTests` covers config/timepoints, arm gating, `site_code`/`study_code` meta, IIEF-5 bands + official wording smoke check, snapshot Codable round-trip (incl. preferences). These do not require ResearchKit.

## Local persistence

`LocalStudyStore` writes `Application Support/XiallaStudies/study-snapshot.json` (atomic). Snapshot includes enrollment, consent, survey answers/scores, reminders, kit stub, consent PDF path, and `StudyPreferences` (splash seen, demo week‑4 flag, resume route, reminder toggle). Quit mid-flow and relaunch — progress restores.

## Branding / Fieldwork

- Logo + homepage hero in `Assets.xcassets`.
  Home hero uses the clean lifestyle photo `HomeHero.png` (image only, no baked-in site text; white wordmark is a SwiftUI overlay). Do not use the OG/social `mmeIf.jpg` crop.
- **Fieldwork Geo** desktop OTFs (Regular / Demibold / Bold) ship under `XiallaStudies/Resources/Fonts/` and are listed in `UIAppFonts`. PostScript names: `Fieldwork-Geo-Regular`, `Fieldwork-Geo-Demibold`, `Fieldwork-Geo-Bold`. `BrandTheme` uses these exclusively (no Avenir). Adobe Fonts / Typekit webfonts must not replace them.
- Chrome: white main screens; primary buttons Pantone 419 C `#212322`; tan Pantone 4665 C `#CDA788` for slider fills and light visual interest only (not full-screen fills). Accent orange remains in the kit but is not used for CTAs or slider tracks.

## Study parameters / provider

`StudyParameters` + `StudyProviderParameters` hold study/site codes, follow-ups, and the participating investigator (Jeff hardcoded for demo). Screens read `StudyConfig.active` / `StudyConfig.provider` so a future DB load can swap the pack without rewriting UI.

## Asset catalog path

`Assets.xcassets` must resolve to `XiallaStudies/Resources/Assets.xcassets`. Regenerate with `python3 scripts/generate_xcodeproj.py` if needed.

## Regenerating the Xcode project

```bash
python3 scripts/generate_xcodeproj.py
# If ResearchKit was bootstrapped:
python3 scripts/wire_researchkit_xcodeproj.py
# or
xcodegen generate && python3 scripts/wire_researchkit_xcodeproj.py
```
