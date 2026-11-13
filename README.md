# Xialla Studies

Prospective-first **ResearchKit** observational study iOS app for Xialla.

> App v1: baseline + **4-week** follow-up only (8/12 weeks structured for later).  
> Records carry `study_code` + `site_code`. Backend is stubbed (Cloud Run / Postgres later).

Suggested bundle ID: `com.xialla.studies`

## Open in Xcode

1. Clone this repo on a Mac with **Xcode 16+** (iOS 17 deployment target).
2. Open `XiallaStudies.xcodeproj` (already generated), **or** regenerate with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

   ```bash
   brew install xcodegen
   xcodegen generate
   open XiallaStudies.xcodeproj
   ```

3. Set your **Team** for signing on the `XiallaStudies` target.
4. Run on a simulator or device.

> This cloud environment has **no Mac/Xcode**. Sources and the project file are complete; compile/test on a Mac.

## ResearchKit dependency

Upstream ResearchKit does **not** ship a root Swift Package today. Official install is an **embedded framework**:

1. Clone ResearchKit (git-lfs required for some assets):

   ```bash
   ./scripts/bootstrap-researchkit.sh
   ```

   or manually:

   ```bash
   git clone https://github.com/ResearchKit/ResearchKit.git Vendor/ResearchKit
   ```

2. In Xcode: **File → Add Files to “XiallaStudies”…** → add `Vendor/ResearchKit/ResearchKit.xcodeproj`.
3. Select the `XiallaStudies` app target → **General → Frameworks, Libraries, and Embedded Content** → add **ResearchKit** and **ResearchKitUI** (Embed & Sign).
4. Build. ResearchKit presenters (`#if canImport(ResearchKit)`) activate automatically.

**CocoaPods alternative** (vendored xcframeworks; needs git-lfs):

```bash
pod install
open XiallaStudies.xcworkspace
```

Without ResearchKit linked, the branded SwiftUI consent/survey stubs still run; RK sheets show a fallback.

## What’s scaffolded

| Area | Status |
|------|--------|
| Splash / Home / Settings | Branded SwiftUI shell |
| Eligibility | Prospective enabled; current-user add-on gated |
| Consent | Info → comprehension stub → signature; RK task wrapper |
| Surveys | IIEF-5 + history + usability/comfort/satisfaction + AE + free text stubs |
| Week-4 follow-up | Wired; local reminder scheduler stub |
| Config | `STUDY_CODE` / `SITE_CODE` placeholders in `StudyConfig` |
| Persistence | Local JSON snapshot |
| API | `StudyAPIClient` protocol + stub / live placeholders |
| Kit fulfillment | Stub only (timing TBD with Jeff) |
| Tests | Model / scoring / snapshot unit tests |

## Study flow (v1)

```
Splash → Home → Eligibility (prospective)
      → Consent → Baseline instruments
      → Local week-4 reminder
      → Week-4 follow-up → Complete
```

## Config placeholders

Edit `XiallaStudies/Config/StudyConfig.swift`:

- `studyCode` → replace `STUDY_CODE`
- `siteCode` → replace `SITE_CODE` (first site: Dr. Jeffrey Campbell / St. Joseph’s London)
- `apiBaseURL` → Cloud Run URL when available

## Next steps

1. Create Apple Developer App ID `com.xialla.studies` and enable signing.
2. Drop IRB-approved consent copy into ResearchKit consent sections.
3. Clear IIEF-5 licensing before shipping real item wording.
4. Implement `LiveStudyAPIClient` against Cloud Run + Postgres.
5. Confirm kit fulfillment timing with Jeff; replace kit stub.
6. TestFlight internal build once ResearchKit is linked.

See `docs/BUILD_NOTES.md` for environment / no-Mac notes.
