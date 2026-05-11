#!/usr/bin/env bash
# Regenera ícones na grelha (iOS AppIcon.appiconset + Android mipmap) a partir de
# assets/images/Appicon.png (ver image_path em pubspec.yaml).
# Depois: clean build, apagar a app do telemóvel, reinstalar.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SRC="$ROOT/assets/images/Appicon.png"
IOS="$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
AND="$ROOT/android/app/src/main/res"

if [[ ! -f "$SRC" ]]; then
  echo "Erro: não existe $SRC"
  exit 1
fi

regenerate_sips() {
  echo "A usar sips (macOS) para gerar os PNGs…"
  resample() { sips -z "$2" "$2" "$SRC" --out "$1" >/dev/null; }
  resample "$IOS/Icon-App-20x20@1x.png" 20
  resample "$IOS/Icon-App-20x20@2x.png" 40
  resample "$IOS/Icon-App-20x20@3x.png" 60
  resample "$IOS/Icon-App-29x29@1x.png" 29
  resample "$IOS/Icon-App-29x29@2x.png" 58
  resample "$IOS/Icon-App-29x29@3x.png" 87
  resample "$IOS/Icon-App-40x40@1x.png" 40
  resample "$IOS/Icon-App-40x40@2x.png" 80
  resample "$IOS/Icon-App-40x40@3x.png" 120
  resample "$IOS/Icon-App-60x60@2x.png" 120
  resample "$IOS/Icon-App-60x60@3x.png" 180
  resample "$IOS/Icon-App-76x76@1x.png" 76
  resample "$IOS/Icon-App-76x76@2x.png" 152
  resample "$IOS/Icon-App-83.5x83.5@2x.png" 167
  resample "$IOS/Icon-App-1024x1024@1x.png" 1024
  resample "$AND/mipmap-mdpi/launcher_icon.png" 48
  resample "$AND/mipmap-hdpi/launcher_icon.png" 72
  resample "$AND/mipmap-xhdpi/launcher_icon.png" 96
  resample "$AND/mipmap-xxhdpi/launcher_icon.png" 144
  resample "$AND/mipmap-xxxhdpi/launcher_icon.png" 192
  resample "$AND/mipmap-mdpi/ic_launcher.png" 48
  resample "$AND/mipmap-hdpi/ic_launcher.png" 72
  resample "$AND/mipmap-xhdpi/ic_launcher.png" 96
  resample "$AND/mipmap-xxhdpi/ic_launcher.png" 144
  resample "$AND/mipmap-xxxhdpi/ic_launcher.png" 192
  echo "Ícones iOS/Android atualizados a partir de Appicon.png."
}

if command -v dart >/dev/null 2>&1; then
  dart pub get
  dart run flutter_launcher_icons
  echo "Feito (flutter_launcher_icons)."
elif command -v sips >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
  regenerate_sips
else
  echo "Instala o Flutter no PATH ou corre isto num Mac com 'sips'."
  exit 1
fi

echo "Seguinte: Product → Clean Build Folder (Xcode), apaga a app do telemóvel, volta a instalar."
