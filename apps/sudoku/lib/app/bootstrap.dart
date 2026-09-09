import 'package:core_ads/core_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_config.dart';
import 'providers.dart';

/// Shared entry point for every flavor. Order matters:
/// 1. platform bindings
/// 2. local storage
/// 3. consent (UMP) — must finish before the ads SDK initialises
/// 4. ads SDK init + pre-load (not awaited: first frame should not wait)
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final AdService ads;
  if (kIsWeb) {
    ads = NoopAdService();
  } else {
    final consent = ConsentManager(forceEea: config.forceEeaConsent);
    final canRequestAds = await consent.gatherConsent();
    ads = canRequestAds ? AdMobAdService(ids: config.adUnitIds) : NoopAdService();
    // Fire and forget — ads warm up while the home screen renders.
    // ignore: unawaited_futures
    ads.initialize();
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        adServiceProvider.overrideWithValue(ads),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SudokuApp(),
    ),
  );
}
