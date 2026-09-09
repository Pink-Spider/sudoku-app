#!/usr/bin/env bash
# Rasterize tool/app_icon.svg into the iOS AppIcon set.
# iOS icons must be opaque (no alpha), so every size is flattened.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
SVG=tool/app_icon.svg
OUT=ios/Runner/Assets.xcassets/AppIcon.appiconset

render() { # px, filename
  rsvg-convert -w "$1" -h "$1" "$SVG" -o "$OUT/$2.tmp.png"
  magick "$OUT/$2.tmp.png" -background white -flatten -alpha off -define png:color-type=2 "PNG24:$OUT/$2"
  rm -f "$OUT/$2.tmp.png"
}

render 40   Icon-App-20x20@2x.png
render 60   Icon-App-20x20@3x.png
render 20   Icon-App-20x20@1x.png
render 29   Icon-App-29x29@1x.png
render 58   Icon-App-29x29@2x.png
render 87   Icon-App-29x29@3x.png
render 40   Icon-App-40x40@1x.png
render 80   Icon-App-40x40@2x.png
render 120  Icon-App-40x40@3x.png
render 120  Icon-App-60x60@2x.png
render 180  Icon-App-60x60@3x.png
render 76   Icon-App-76x76@1x.png
render 152  Icon-App-76x76@2x.png
render 167  Icon-App-83.5x83.5@2x.png
render 1024 Icon-App-1024x1024@1x.png

echo "app icons regenerated from $SVG"

# Launch screen mark (centred on the storyboard's white background).
LAUNCH=ios/Runner/Assets.xcassets/LaunchImage.imageset
render_launch() { # px, filename
  rsvg-convert -w "$1" -h "$1" tool/launch_mark.svg -o "$LAUNCH/$2"
}
render_launch 200 LaunchImage.png
render_launch 400 LaunchImage@2x.png
render_launch 600 LaunchImage@3x.png
echo "launch images regenerated from tool/launch_mark.svg"
