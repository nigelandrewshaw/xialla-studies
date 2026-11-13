#!/usr/bin/env bash
# Clone ResearchKit into Vendor/ and optionally patch project.yml for XcodeGen.
# On a Mac: run this, then `xcodegen generate` (or use the checked-in xcodeproj + Add Files).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/Vendor/ResearchKit"
# Prefer user's fork if RESEARCHKIT_URL is set; default upstream.
REPO_URL="${RESEARCHKIT_URL:-https://github.com/ResearchKit/ResearchKit.git}"
# Alternate: https://github.com/nigelandrewshaw/ResearchKit.git

clone_rk() {
  if [[ -d "$VENDOR/.git" ]]; then
    echo "ResearchKit already present at $VENDOR"
    return 0
  fi
  mkdir -p "$ROOT/Vendor"
  echo "Cloning ResearchKit into Vendor/ResearchKit…"
  echo "  URL: $REPO_URL"
  if command -v git-lfs >/dev/null 2>&1; then
    git lfs install || true
  else
    echo "Note: git-lfs not found; some RK assets may be missing. brew install git-lfs"
  fi
  git clone --depth 1 "$REPO_URL" "$VENDOR"
  echo "Clone done."
}

print_xcode_steps() {
  cat <<'EOF'

Next (Mac / Xcode):
  1. Open XiallaStudies.xcodeproj
  2. File → Add Files to "XiallaStudies"… → select Vendor/ResearchKit/ResearchKit.xcodeproj
  3. App target → General → Frameworks, Libraries, and Embedded Content
       → add ResearchKit + ResearchKitUI (Embed & Sign)
  4. Build & Run

Or with XcodeGen after clone:
  brew install xcodegen
  # project.yml already lists an optional local path — uncomment local packages if using SPM-style,
  # otherwise keep the embedded .xcodeproj approach above (official RK install).
  xcodegen generate
  open XiallaStudies.xcodeproj

Without ResearchKit linked, branded SwiftUI consent/survey fallbacks still run
(IIEF-5 sliders 1–5 default 3). #if canImport(ResearchKit) activates real ORK tasks once linked.
EOF
}

clone_rk
print_xcode_steps

# Touch a stamp so CI/docs can detect bootstrap.
mkdir -p "$ROOT/Vendor"
echo "bootstrapped=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$ROOT/Vendor/ResearchKit.bootstrap.stamp"
echo "Wrote Vendor/ResearchKit.bootstrap.stamp"
