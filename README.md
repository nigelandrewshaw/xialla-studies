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
   open XiallaStudies.xcodeproj
   ```

2. Select the **XiallaStudies** scheme → set your **Team** for signing.
3. Run on a simulator or device.
4. Walkthrough: Splash → Eligibility → Consent → Baseline (IIEF-5 sliders default **3**) → Home → Settings → **Demo: jump to week 4** → Week‑4 surveys → Reminders / Investigator profile.

> Optional: `./scripts/bootstrap-researchkit.sh` then embed ResearchKit + ResearchKitUI for native ORK chrome. Without it, branded SwiftUI fallbacks still complete the full demo.

## ResearchKit dependency

```bash
./scripts/bootstrap-researchkit.sh
# optional: RESEARCHKIT_URL=https://github.com/nigelandrewshaw/ResearchKit.git ./scripts/bootstrap-researchkit.sh
```

Then in Xcode: add `Vendor/ResearchKit/ResearchKit.xcodeproj` → embed **ResearchKit** + **ResearchKitUI**.

## What’s included

| Area | Status |
|------|--------|
| Splash / Home | Full-bleed xialla.com hero + logo |
| Provider | `StudyParameters.provider` → Dr. Jeffrey Campbell profile |
| Eligibility | Prospective enabled; current-user gated |
| Consent | Info → comprehension → signature; RK + PDF when linked |
| Surveys | IIEF-5 sliders **1–5 default 3** + history / UX / AE |
| Week-4 | Real path + **demo advance** / seed in Settings |
| Reminders | Local notification scheduler (~4 weeks) |
| Persistence | `LocalStudyStore` JSON — survives relaunch |
| Config | `study_code` / `site_code` + study parameters model |
| Tests | Model / scoring / snapshot round-trip |

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

See `docs/BUILD_NOTES.md` for Fieldwork font licensing, assets, and no-Mac notes.
