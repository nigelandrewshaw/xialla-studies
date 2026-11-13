# Build notes (no Mac in CI/cloud agent)

## Environment

The scaffolding agent ran on Linux without Xcode / `xcodebuild` / iOS Simulator. Therefore:

- Sources, `project.yml`, and `XiallaStudies.xcodeproj` were generated here.
- **Compile and UI tests must run on a Mac** with Xcode 16+.
- The app is **native SwiftUI only** — ResearchKit is not a dependency.

## Mac: open, sign, run

```bash
git pull
open XiallaStudies.xcodeproj
# Select XiallaStudies scheme → Signing & Capabilities → your Team
# Run on simulator or device
```

If you previously cloned ResearchKit under `Vendor/` or embedded ResearchKit / ResearchKitUI frameworks, remove those local refs after pull — they are unused.

## Consent (native)

Branded multi-step eConsent:

1. Purpose  
2. Procedures  
3. Data use  
4. Risks and benefits  
5. Voluntary participation / withdrawal  
6. Comprehension check  
7. First name + last name (UIKit `FocusableTextField`, Simulator-keyboard friendly) + PencilKit signature pad (finger / Apple Pencil) + date  

Signature PNG and a lightweight consent PDF are written under the app Documents directory; `ConsentRecord.signatureBlobRef` and `consentPDFPath` persist via `LocalStudyStore`. Sign & join requires non-empty names and ink on the pad. There is no typed “Full name” / ResearchKit-fallback signature screen — Home/eligibility route only to `ConsentFlowView`.

Fieldwork Geo body copy on consent screens uses **16pt** (+1pt vs earlier stubs). No header/icon overlays on review sections.

## Surveys (native)

IIEF-5 and companion instruments use branded SwiftUI (`InstrumentSurveyView`): official item wording, 1–5 sliders defaulting to **3**, tan `#CDA788` filled tracks. Primary CTAs remain black `#212322` on white canvases.

`KeyboardAvoidingFormScroll` wraps instrument sheets so AE / free-text editors and IIEF-5 (all 5 items + Save) scroll above the keyboard. Save awaits `LocalStudyStore` persistence and marks the instrument `.completed` before the sheet dismisses (status shows Done after relaunch). Sheet dismiss control is **Cancel**.

## Unit tests

`XiallaStudiesTests` covers config/timepoints, arm gating, `site_code`/`study_code` meta, IIEF-5 bands + official wording smoke check, snapshot Codable round-trip (incl. preferences).

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
# or
brew install xcodegen && xcodegen generate
```
