#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

"$SCRIPT_DIR/prepare_build.sh"

cd "$PROJECT_DIR"
flutter "$@"

