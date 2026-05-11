#!/usr/bin/env bash
# Use sempre DEPOIS de flutter clean: regenera Generated.xcconfig e Pods na ordem certa.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
flutter pub get
(cd ios && pod install)
echo "OK. Na raiz do repo corre: flutter run"
