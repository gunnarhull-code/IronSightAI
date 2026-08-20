#!/usr/bin/env bash
# Build the real Android debug APK so AGP/plugin regressions fail CI.
# Does not deploy, connect to production, or apply migrations.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -f .env ]; then
  if [ ! -f .env.example ]; then
    echo "error: required safe test configuration is unavailable (.env.example missing)" >&2
    exit 1
  fi
  cp .env.example .env
fi

flutter pub get
flutter build apk --debug

APK="build/app/outputs/flutter-apk/app-debug.apk"
test -f "$APK"
echo "Android debug APK built: $APK ($(wc -c <"$APK") bytes)"
