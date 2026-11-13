# Build notes (no Mac in CI/cloud agent)

## Environment

The scaffolding agent ran on Linux without Xcode / `xcodebuild` / iOS Simulator. Therefore:

- Sources, `project.yml`, and `XiallaStudies.xcodeproj` were generated here.
- **Compile and UI tests must run on a Mac** with Xcode 16+.
- ResearchKit is **not** vendored in this commit (large + git-lfs). Use `scripts/bootstrap-researchkit.sh` on a Mac.

## Verify on Mac

```bash
# Optional regenerate
xcodegen generate

# Link ResearchKit (see README), then:
xcodebuild -scheme XiallaStudies -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Unit tests / simulator without ResearchKit

`XiallaStudiesTests` covers config/timepoints, arm gating, `site_code`/`study_code` meta, IIEF-5 bands, and snapshot Codable round-trip. These do not require ResearchKit.

The app target does **not** link ResearchKit by default (empty Frameworks phase). Presenters use `#if canImport(ResearchKit)` stubs, so a simulator build should compile and link without ResearchKit. Optional: `./scripts/bootstrap-researchkit.sh` then embed ResearchKit + ResearchKitUI (see README).

## Asset catalog path

`Assets.xcassets` must resolve to `XiallaStudies/Resources/Assets.xcassets` (group: XiallaStudies → Resources → Assets.xcassets). Regenerate with `python3 scripts/generate_xcodeproj.py` if the catalog shows as Recovered References or Xcode looks for `./Assets.xcassets` at the repo root.

## Regenerating the Xcode project

```bash
python3 scripts/generate_xcodeproj.py
# or
xcodegen generate
```
