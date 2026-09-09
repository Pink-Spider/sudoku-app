#!/usr/bin/env bash
# One-time (idempotent) project bootstrap. Run from anywhere:
#   ./scripts/bootstrap.sh
#
# 1. checks the Flutter toolchain
# 2. resolves the pub workspace
# 3. generates android/ + ios/ for apps/sudoku if missing (flutter create)
# 4. patches AdMob app ids (test ids) + minSdk into the platform projects
# 5. generates localizations, runs analyze + all tests
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/apps/sudoku"
ORG="io.pinkspider"

# AdMob *app* ids — Google's official test ids. Replace with your real
# ones (AdMob console → Apps → App settings) before a store release.
ADMOB_APP_ID_ANDROID="ca-app-pub-3940256099942544~3347511713"
ADMOB_APP_ID_IOS="ca-app-pub-3940256099942544~1458002511"

say() { printf '\n\033[1;34m▶ %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✖ %s\033[0m\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- 1. toolchain
say "Checking Flutter"
command -v flutter >/dev/null || die "flutter not on PATH. Install: https://docs.flutter.dev/get-started/install/macos"
FLUTTER_VERSION="$(flutter --version --machine 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])')"
python3 - "$FLUTTER_VERSION" <<'PY' || die "Flutter >= 3.29 required (found $FLUTTER_VERSION). Run: flutter upgrade"
import sys
v = tuple(int(x) for x in sys.argv[1].split('.')[:2])
sys.exit(0 if v >= (3, 29) else 1)
PY
echo "Flutter $FLUTTER_VERSION"

# ------------------------------------------------------------- 2. workspace
say "Resolving pub workspace"
cd "$ROOT"
flutter pub get

# ------------------------------------------------------ 3. platform folders
cd "$APP"
if [[ ! -d android || ! -d ios ]]; then
  say "Generating android/ and ios/ (flutter create)"
  # Keep our files: flutter create must not touch these.
  tmp="$(mktemp -d)"
  cp pubspec.yaml "$tmp/pubspec.yaml"
  cp -R lib "$tmp/lib"
  [[ -d test ]] && cp -R test "$tmp/test"
  flutter create --no-pub --platforms=android,ios --org "$ORG" --project-name sudoku . >/dev/null
  cp "$tmp/pubspec.yaml" pubspec.yaml
  rm -rf lib && cp -R "$tmp/lib" lib
  if [[ -d "$tmp/test" ]]; then rm -rf test && cp -R "$tmp/test" test; fi
  rm -f test/widget_test.dart 2>/dev/null || true
  # The template's analysis_options would shadow the workspace one.
  rm -f analysis_options.yaml
  rm -rf "$tmp"
  # Re-resolve now that platform plugins can be registered.
  (cd "$ROOT" && flutter pub get)
else
  echo "android/ and ios/ already exist — skipping flutter create"
fi

# ----------------------------------------------------- 4. platform patches
say "Patching Android (AdMob app id, minSdk 23)"
MANIFEST="android/app/src/main/AndroidManifest.xml"
if ! grep -q "com.google.android.gms.ads.APPLICATION_ID" "$MANIFEST"; then
  python3 - "$MANIFEST" "$ADMOB_APP_ID_ANDROID" <<'PY'
import sys, re
path, app_id = sys.argv[1], sys.argv[2]
s = open(path).read()
meta = f'''        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="{app_id}"/>
'''
# insert right after the opening <application ...> tag
s = re.sub(r'(<application\b[^>]*>\n)', r'\1' + meta, s, count=1)
open(path, 'w').write(s)
PY
fi
if [[ -f android/app/build.gradle.kts ]]; then
  sed -i '' -E 's/minSdk = flutter\.minSdkVersion/minSdk = 23/' android/app/build.gradle.kts
elif [[ -f android/app/build.gradle ]]; then
  sed -i '' -E 's/minSdkVersion flutter\.minSdkVersion/minSdkVersion 23/; s/minSdk = flutter\.minSdkVersion/minSdk = 23/' android/app/build.gradle
fi

say "Patching iOS (AdMob app id, ATT text, SKAdNetwork)"
PLIST="ios/Runner/Info.plist"
plutil -replace GADApplicationIdentifier -string "$ADMOB_APP_ID_IOS" "$PLIST"
plutil -replace NSUserTrackingUsageDescription -string \
  "This identifier will be used to deliver personalized ads to you." "$PLIST"
if ! plutil -extract SKAdNetworkItems raw "$PLIST" >/dev/null 2>&1; then
  # Google's own network id. Add the full list from
  # https://developers.google.com/admob/ios/ios14#skadnetwork before release.
  plutil -insert SKAdNetworkItems -json \
    '[{"SKAdNetworkIdentifier":"cstr6suwn9.skadnetwork"}]' "$PLIST"
fi
# AdMob SDK needs iOS 13+; Flutter templates already target >= 13 on
# recent versions, but make sure the Podfile pins it.
if [[ -f ios/Podfile ]]; then
  sed -i '' -E "s/^# platform :ios, '[0-9.]+'/platform :ios, '13.0'/" ios/Podfile
fi

# --------------------------------------------------------- 5. generate + verify
say "Generating localizations"
flutter gen-l10n

say "flutter analyze"
cd "$ROOT"
flutter analyze

say "Running tests"
(cd packages/puzzle_engine && dart test)
(cd packages/rules_sudoku && dart test)
(cd packages/core_ads && flutter test)
(cd apps/sudoku && flutter test)

say "Done. Next:"
cat <<EOF
  cd apps/sudoku
  flutter run -t lib/main_dev.dart          # dev flavor (test ads)
  flutter run -t lib/main_prod.dart         # prod entrypoint

  Before a store release:
   - real AdMob app ids in AndroidManifest.xml / Info.plist (this script)
   - real ad unit ids in lib/app/app_config.dart (AppConfig.prod)
   - configure the GDPR message in AdMob → Privacy & messaging
   - add Firebase (google-services.json / GoogleService-Info.plist) and
     a Firebase-backed AnalyticsService / RemoteConfigService
EOF
