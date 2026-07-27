#!/usr/bin/env bash
# Lightweight local verification matching GitHub Actions CI.
# Does not start Supabase, deploy, or apply migrations.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -f .env ]; then
  if [ ! -f .env.example ]; then
    echo "error: required safe test configuration is unavailable (.env.example missing)" >&2
    exit 1
  fi
  echo "Creating .env from .env.example for local verification..."
  cp .env.example .env
fi

flutter pub get
dart format --output=none --set-exit-if-changed .
dart run tool/verify_sprint_registry.dart
flutter analyze
flutter test

echo "Verification passed."
