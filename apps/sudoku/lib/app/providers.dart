import 'package:core_ads/core_ads.dart';
import 'package:core_analytics/core_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_engine/puzzle_engine.dart';
import 'package:rules_sudoku/rules_sudoku.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/game/game_persistence.dart';
import 'app_config.dart';

/// Overridden in `bootstrap.dart` with the real instances. Throwing
/// defaults make a missing override an immediate, obvious failure.
final appConfigProvider = Provider<AppConfig>((_) => throw UnimplementedError());
final adServiceProvider = Provider<AdService>((_) => throw UnimplementedError());

/// Same instance the startup flow used, so the settings entry point can
/// reopen the UMP privacy form. GDPR requires consent to be withdrawable,
/// so this is not optional once a consent message is published.
final consentManagerProvider =
    Provider<ConsentManager>((_) => throw UnimplementedError());
final sharedPreferencesProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError());

final analyticsProvider =
    Provider<AnalyticsService>((_) => const DebugAnalyticsService());

final remoteConfigProvider =
    Provider<RemoteConfigService>((_) => LocalRemoteConfigService());

final interstitialGateProvider = Provider<InterstitialGate>((ref) {
  final rc = ref.watch(remoteConfigProvider);
  return InterstitialGate(
    config: InterstitialGateConfig(
      enabled: rc.getBool(RemoteConfigKeys.interstitialEnabled),
      everyNthEvent: rc.getInt(RemoteConfigKeys.interstitialEveryNth),
      minInterval:
          Duration(seconds: rc.getInt(RemoteConfigKeys.interstitialMinIntervalSec)),
      sessionGrace:
          Duration(seconds: rc.getInt(RemoteConfigKeys.interstitialSessionGraceSec)),
    ),
  )..startSession();
});

/// The rule this app is built around. A Killer Sudoku app overrides this
/// single provider (and its own generator) — the rest of the UI is shared.
final puzzleRuleProvider = Provider<PuzzleRule>((_) => const SudokuRule());

final gamePersistenceProvider = Provider<GamePersistence>(
  (ref) => GamePersistence(ref.watch(sharedPreferencesProvider)),
);
