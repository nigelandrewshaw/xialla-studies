#!/usr/bin/env bash
# Clone ResearchKit into Vendor/ and wire it into XiallaStudies.xcodeproj
# (subproject + Embed & Sign for ResearchKit + ResearchKitUI).
#
# On a Mac after this script:
#   open XiallaStudies.xcodeproj
#   Select Team → Build & Run
#
# See docs/BUILD_NOTES.md for full Mac steps.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/Vendor/ResearchKit"
REPO_URL="${RESEARCHKIT_URL:-https://github.com/ResearchKit/ResearchKit.git}"
# Alternate fork: RESEARCHKIT_URL=https://github.com/nigelandrewshaw/ResearchKit.git

clone_rk() {
  if [[ -d "$VENDOR/.git" ]]; then
    echo "ResearchKit already present at $VENDOR"
    if [[ "${RESEARCHKIT_UPDATE:-0}" == "1" ]]; then
      echo "RESEARCHKIT_UPDATE=1 — fetching…"
      git -C "$VENDOR" fetch --depth 1 origin
      git -C "$VENDOR" reset --hard FETCH_HEAD || true
    fi
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

wire_xcodeproj() {
  if [[ ! -d "$VENDOR/ResearchKit.xcodeproj" ]]; then
    echo "ERROR: Expected $VENDOR/ResearchKit.xcodeproj after clone." >&2
    exit 1
  fi

  # Regenerate base project (keeps sources in sync), then wire RK subproject.
  if [[ -f "$ROOT/scripts/generate_xcodeproj.py" ]]; then
    echo "Regenerating XiallaStudies.xcodeproj…"
    python3 "$ROOT/scripts/generate_xcodeproj.py"
  fi

  echo "Wiring ResearchKit + ResearchKitUI into Xcode project…"
  python3 "$ROOT/scripts/wire_researchkit_xcodeproj.py"

  # Optional XcodeGen path — keep project.yml in sync for Mac regenerators.
  if command -v xcodegen >/dev/null 2>&1 && [[ -f "$ROOT/project.yml" ]]; then
    echo "xcodegen found — you may run: xcodegen generate && python3 scripts/wire_researchkit_xcodeproj.py"
  fi
}

print_mac_steps() {
  cat <<'EOF'

Next (Mac / Xcode 16+):
  1. open XiallaStudies.xcodeproj
  2. Select the XiallaStudies target → Signing & Capabilities → choose your Team
  3. Build & Run on a simulator or device

  The bootstrap script already:
    • cloned Vendor/ResearchKit (gitignored)
    • regenerated XiallaStudies.xcodeproj
    • added ResearchKit.xcodeproj as a subproject
    • linked + Embed & Sign ResearchKit + ResearchKitUI

  If Xcode shows missing frameworks after a clean clone:
    ./scripts/bootstrap-researchkit.sh
    # or only re-wire: python3 scripts/wire_researchkit_xcodeproj.py

  Branded SwiftUI bookends still wrap ORK tasks (consent intro / survey hub).
  Without ResearchKit linked, #if canImport fallbacks keep the demo runnable.

  Theme: white canvases, primary buttons #212322, tan #CDA788 slider fill.
EOF
}

clone_rk
wire_xcodeproj
print_mac_steps

mkdir -p "$ROOT/Vendor"
echo "bootstrapped=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$ROOT/Vendor/ResearchKit.bootstrap.stamp"
echo "Wrote Vendor/ResearchKit.bootstrap.stamp"
echo "Done."
