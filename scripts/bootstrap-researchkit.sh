#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/Vendor/ResearchKit"

if [[ -d "$VENDOR/.git" ]]; then
  echo "ResearchKit already present at $VENDOR"
  exit 0
fi

mkdir -p "$ROOT/Vendor"
echo "Cloning ResearchKit into Vendor/ResearchKit (git-lfs recommended)…"
if command -v git-lfs >/dev/null 2>&1; then
  git lfs install
fi
git clone --depth 1 https://github.com/ResearchKit/ResearchKit.git "$VENDOR"
echo "Done. Add ResearchKit.xcodeproj to the app target (see README)."
