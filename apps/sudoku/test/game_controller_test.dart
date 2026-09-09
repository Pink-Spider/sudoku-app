import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_engine/puzzle_engine.dart';
import 'package:sudoku/app/providers.dart';
import 'package:sudoku/features/game/game_controller.dart';

import 'test_overrides.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late GameController controller;

  setUp(() async {
    container = ProviderContainer(overrides: await testOverrides());
    controller = container.read(gameControllerProvider.notifier);
  });

  tearDown(() async {
    await controller.abandon();
    container.dispose();
  });

  test('startNew produces a playable state and persists it', () async {
    await controller.startNew(Difficulty.easy, seed: 1);
    final s = container.read(gameControllerProvider)!;
    expect(s.board.length, 81);
    expect(s.status, GameStatus.playing);
    expect(s.freeHintsLeft, 1);
    expect(container.read(gamePersistenceProvider).hasSession, isTrue);
  });

  test('input records mistakes and correct values', () async {
    await controller.startNew(Difficulty.easy, seed: 2);
    var s = container.read(gameControllerProvider)!;
    final empty = s.board.indexOf(0);
    final answer = s.puzzle.solution[empty];
    final wrong = answer == 9 ? 1 : answer + 1;

    controller.select(empty);
    controller.input(wrong);
    s = container.read(gameControllerProvider)!;
    expect(s.mistakes, 1);
    expect(s.board[empty], wrong);

    controller.input(answer);
    s = container.read(gameControllerProvider)!;
    expect(s.mistakes, 1);
    expect(s.board[empty], answer);
  });

  test('free hint, then rewarded hint via ad service', () async {
    await controller.startNew(Difficulty.easy, seed: 3);
    expect(await controller.requestHint(), HintOutcome.applied);
    expect(container.read(gameControllerProvider)!.freeHintsLeft, 0);
    // NoopAdService reports the reward as earned.
    expect(await controller.requestHint(), HintOutcome.applied);
    final s = container.read(gameControllerProvider)!;
    expect(s.lastHint, isNotNull);
    expect(s.board[s.lastHint!.index], s.puzzle.solution[s.lastHint!.index]);
  });

  test('resume restores a saved session', () async {
    await controller.startNew(Difficulty.medium, seed: 4);
    final before = container.read(gameControllerProvider)!;
    controller.select(before.board.indexOf(0));
    controller.input(before.puzzle.solution[before.board.indexOf(0)]);
    controller.pause();

    final fresh = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(
        container.read(sharedPreferencesProvider),
      ),
      adServiceProvider.overrideWithValue(container.read(adServiceProvider)),
      appConfigProvider.overrideWithValue(container.read(appConfigProvider)),
    ]);
    addTearDown(fresh.dispose);
    final c2 = fresh.read(gameControllerProvider.notifier);
    expect(c2.resume(), isTrue);
    final after = fresh.read(gameControllerProvider)!;
    expect(after.puzzle.id, before.puzzle.id);
    expect(after.board.where((v) => v != 0).length,
        before.puzzle.givenCount + 1);
    await c2.abandon();
  });
}
