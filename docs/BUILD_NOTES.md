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

## Unit tests without ResearchKit

`XiallaStudiesTests` covers config/timepoints, arm gating, `site_code`/`study_code` meta, IIEF-5 bands, and snapshot Codable round-trip. These do not require ResearchKit.

## Regenerating the Xcode project

```bash
python3 scripts/generate_xcodeproj.py
# or
xcodegen generate
```
