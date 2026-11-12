#!/usr/bin/env bash
# Gera os ícones do Android a partir de assets/icon/*.svg (requer rsvg-convert,
# do pacote librsvg: `brew install librsvg`).
set -euo pipefail
cd "$(dirname "$0")/.."
RES=android/app/src/main/res
ICON=assets/icon
# densidade:tamanho legado (48dp):tamanho adaptativo (108dp)
for d in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  IFS=: read -r name legacy adaptive <<< "$d"
  mkdir -p "$RES/mipmap-$name"
  rsvg-convert -w "$legacy" -h "$legacy" "$ICON/sampletag_icon.svg" -o "$RES/mipmap-$name/ic_launcher.png"
  rsvg-convert -w "$adaptive" -h "$adaptive" "$ICON/foreground.svg" -o "$RES/mipmap-$name/ic_launcher_foreground.png"
  rsvg-convert -w "$adaptive" -h "$adaptive" "$ICON/monochrome.svg" -o "$RES/mipmap-$name/ic_launcher_monochrome.png"
done
# Ícone para a Play Store / README em alta resolução.
rsvg-convert -w 512 -h 512 "$ICON/sampletag_icon.svg" -o "$ICON/sampletag_icon_512.png"
echo "Ícones gerados em $RES"
