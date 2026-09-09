import 'dart:async';

import 'package:core_ads/core_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_config.dart';
import 'providers.dart';

/// Shared entry point for every flavor.
///
/// The first frame is not blocked on the ad stack: the UI starts, and the
/// consent -> ATT -> SDK init chain runs behind it. That ordering is not
/// cosmetic — see [_startAds].
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final AdService ads =
      kIsWeb ? NoopAdService() : AdMobAdService(ids: config.adUnitIds);
  final consent = ConsentManager(forceEea: config.forceEeaConsent);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        adServiceProvider.overrideWithValue(ads),
        consentManagerProvider.overrideWithValue(consent),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SudokuApp(),
    ),
  );

  if (ads is AdMobAdService) unawaited(_startAds(ads, consent));
}

/// Consent, then tracking permission, then the SDK — in that order.
///
/// * UMP first because Google requires consent to be resolved before ATT.
/// * ATT only once a frame has been rendered: iOS silently denies a request
///   made while the app is not yet active, and a denial is permanent.
/// * The SDK last, so its first ad request already knows both answers.
///
/// Banners tolerate arriving before this finishes; [AdBanner] retries.
Future<void> _startAds(AdMobAdService ads, ConsentManager consent) async {
  await WidgetsBinding.instance.endOfFrame;

  final canRequestAds = await consent.gatherConsent();
  await consent.requestTracking();

  if (canRequestAds) {
    await ads.initialize();
  } else {
    debugPrint('[ads] consent withheld, ads disabled for this session');
  }
}
