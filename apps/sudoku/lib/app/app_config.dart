import 'package:core_ads/core_ads.dart';

enum Flavor { dev, prod }

/// Per-flavor configuration. Everything that differs between the store
/// build and the developer build lives here — nothing else in the app
/// checks the flavor directly.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.adUnitIds,
    this.showDebugBanner = false,
    this.forceEeaConsent = false,
  });

  final Flavor flavor;
  final String appName;
  final AdUnitIds adUnitIds;
  final bool showDebugBanner;

  /// Dev only: pretend the device is in the EEA so the consent form shows.
  final bool forceEeaConsent;

  bool get isDev => flavor == Flavor.dev;

  static AppConfig dev() => AppConfig(
        flavor: Flavor.dev,
        appName: 'Sudoku (dev)',
        adUnitIds: AdUnitIds.test(),
        showDebugBanner: true,
        forceEeaConsent: false,
      );

  /// TODO(prod): replace with the real ad unit ids from the AdMob console.
  /// The AdMob *app* ids go in AndroidManifest.xml / Info.plist (see
  /// scripts/bootstrap.sh). Until then prod also uses test ids so a
  /// release build never serves real ads by accident.
  static AppConfig prod() => AppConfig(
        flavor: Flavor.prod,
        appName: 'Sudoku',
        adUnitIds: AdUnitIds.platform(
          android: AdUnitIds.test(),
          ios: AdUnitIds.test(),
        ),
      );
}
