# Xialla Studies

Prospective-first **ResearchKit** observational study iOS app for Xialla.

> App v1: baseline + **4-week** follow-up only (8/12 weeks structured for later).  
> Records carry `study_code` + `site_code`. Backend is stubbed (Cloud Run / Postgres later).  
> Progress persists locally between launches for demos.

Suggested bundle ID: `com.xialla.studies`

## Open in Xcode (Jeff demo)

1. Clone on a Mac with **Xcode 16+** (iOS 17+):

   ```bash
   git clone https://github.com/nigelandrewshaw/xialla-studies.git
   cd xialla-studies
   git checkout cursor/scaffold-ios-study-app-5ff7   # or main once merged
   ./scripts/bootstrap-researchkit.sh                 # clone + wire ResearchKit
   open XiallaStudies.xcodeproj
   ```

2. Select the **XiallaStudies** scheme → set your **Team** for signing.
3. Run on a simulator or device.
4. Walkthrough: Splash → Eligibility → Consent (ORK when linked) → Baseline (official IIEF-5, sliders default **3**, tan fill) → Home → Settings → **Demo: jump to week 4** → Week‑4 surveys → Reminders / Investigator profile.

> Without bootstrap, branded SwiftUI fallbacks still complete the full demo. See `docs/BUILD_NOTES.md` for Mac wiring details.

## ResearchKit dependency

```bash
./scripts/bootstrap-researchkit.sh
# optional: RESEARCHKIT_URL=https://github.com/nigelandrewshaw/ResearchKit.git ./scripts/bootstrap-researchkit.sh
```

Bootstrap clones `Vendor/ResearchKit` (gitignored) and wires **ResearchKit** + **ResearchKitUI** into the checked-in Xcode project (link + Embed & Sign). No manual Add Files step required after a successful run.

## What’s included

| Area | Status |
|------|--------|
| Splash / Home | Full-bleed xialla.com hero + logo; white content canvas |
| Provider | `StudyParameters.provider` → Dr. Jeffrey Campbell profile |
| Eligibility | Prospective enabled; current-user gated |
| Consent | ORK visual consent → comprehension → signature → PDF when linked |
| Surveys | Official IIEF-5 wording; sliders **1–5 default 3** (tan fill) + history / UX / AE |
| Chrome | White screens; primary buttons `#212322`; tan `#CDA788` accents |
| Week-4 | Real path + **demo advance** / seed in Settings |
| Reminders | Local notification scheduler (~4 weeks) |
| Persistence | `LocalStudyStore` JSON — survives relaunch |
| Config | `study_code` / `site_code` + study parameters model |
| Tests | Model / scoring / official IIEF-5 wording / snapshot round-trip |

## Study flow (v1)

```
Splash → Home → Eligibility (prospective)
      → Consent → Baseline instruments
      → Local week-4 reminder
      → Week-4 follow-up → Complete
```

## Config

Edit `StudyParameters.xiallaObservationalV1` / `StudyConfig.active` (or later load from DB):

- `studyCode` / `siteCode`
- `provider` (name, photo asset, title, site, bio)
- `apiBaseURL` when Cloud Run is live

See `docs/BUILD_NOTES.md` for Fieldwork font licensing, ResearchKit Mac steps, assets, and no-Mac notes.
