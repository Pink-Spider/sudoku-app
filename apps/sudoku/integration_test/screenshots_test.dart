// Store screenshot harness.
//
//   ./tool/screenshots.sh
//
// Drives the real widget tree to a handful of chosen states and captures
// each one at the simulator's native resolution, for every supported
// locale. Deliberately does NOT go through bootstrap(): screenshots must
// be deterministic and ad-free, so ads are the no-op service, consent
// never runs, and every puzzle comes from a fixed seed.
import 'package:core_ads/core_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:puzzle_engine/puzzle_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku/app/app.dart';
import 'package:sudoku/app/app_config.dart';
import 'package:sudoku/app/providers.dart';
import 'package:sudoku/features/game/game_controller.dart';

/// Locales to shoot. Must stay in step with the ARB files.
const _locales = ['en', 'ko', 'ja', 'de'];

/// Fixed so a re-shoot produces the same board, which makes it obvious in
/// review when a screenshot changed because the UI changed.
const _seed = 20260909;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in _locales) {
    testWidgets('screenshots — $locale', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.prod()),
          adServiceProvider.overrideWithValue(NoopAdService()),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: SudokuApp(locale: Locale(locale)),
        ),
      );
      await tester.pumpAndSettle();

      // iOS needs the Flutter surface converted before it can be read back.
      await binding.convertFlutterSurfaceToImage();

      Future<void> shoot(String name) async {
        await tester.pumpAndSettle();
        await binding.takeScreenshot('$locale-$name');
      }

      // 1. Home: difficulty choice and the daily challenge.
      await shoot('1-home');

      // 2. A board part-way through, with a cell selected so the row /
      //    column / box highlighting is visible.
      final controller = container.read(gameControllerProvider.notifier);
      await controller.startNew(Difficulty.medium, seed: _seed);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      final state = container.read(gameControllerProvider)!;
      final solution = state.puzzle.solution;
      // Fill a realistic-looking chunk of the board.
      var filled = 0;
      for (var i = 0; i < state.board.length && filled < 14; i++) {
        if (state.board[i] != 0) continue;
        controller.select(i);
        controller.input(solution[i]);
        filled++;
      }
      // Land on an empty cell so the selection highlight reads clearly.
      final empty = container.read(gameControllerProvider)!.board.indexOf(0);
      controller.select(empty);
      await shoot('2-board');

      // 3. The explained hint — the thing rewarded ads are sold against.
      await controller.requestHint();
      await shoot('3-hint');

      // 4. Notes mode, showing pencil marks.
      final c2 = container.read(gameControllerProvider.notifier);
      final next = container.read(gameControllerProvider)!.board.indexOf(0);
      c2.select(next);
      c2.toggleNotesMode();
      for (final v in [2, 5, 7]) {
        c2.input(v);
      }
      await shoot('4-notes');

      container.read(gameControllerProvider.notifier).pause();
    });
  }
}
