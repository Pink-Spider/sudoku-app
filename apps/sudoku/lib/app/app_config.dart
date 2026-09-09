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
    this.umpTestDeviceIds = const [],
    this.resetConsentOnLaunch = false,
  });

  final Flavor flavor;
  final String appName;
  final AdUnitIds adUnitIds;
  final bool showDebugBanner;

  /// Dev only: pretend the device is in the EEA so the consent form shows.
  ///
  /// Has **no effect on its own**. Google only honours a debug geography on
  /// a device listed in [umpTestDeviceIds].
  final bool forceEeaConsent;

  /// UMP test device hashes. Run the app once and the native UMP SDK logs
  /// the hash for this device; pass it back in (see [dev]).
  final List<String> umpTestDeviceIds;

  /// Dev only: forget the stored consent at startup so the form appears on
  /// every launch. Without it the form shows once and never again.
  final bool resetConsentOnLaunch;

  bool get isDev => flavor == Flavor.dev;

  /// Device hashes come from the command line so no one has to edit (and
  /// then accidentally commit) a device id:
  ///
  /// ```
  /// flutter run -t lib/main_dev.dart \
  ///   --dart-define=UMP_TEST_DEVICE_IDS=<hash>[,<hash>]
  /// ```
  ///
  /// Run once without it, find the hash in the log line the UMP SDK prints
  /// ("Use ConsentDebugSettings... addTestDeviceHashedId(\"...\")"), then
  /// re-run with it.
  static const _umpTestDeviceIds =
      String.fromEnvironment('UMP_TEST_DEVICE_IDS');

  static AppConfig dev() {
    final ids = _umpTestDeviceIds.isEmpty
        ? const <String>[]
        : _umpTestDeviceIds.split(',').map((e) => e.trim()).toList();
    return AppConfig(
      flavor: Flavor.dev,
      appName: 'Sudoku (dev)',
      adUnitIds: AdUnitIds.test(),
      showDebugBanner: true,
      // Korea is not a consent region, so without this the form is skipped
      // and there is nothing to test.
      forceEeaConsent: true,
      umpTestDeviceIds: ids,
      resetConsentOnLaunch: true,
    );
  }

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
