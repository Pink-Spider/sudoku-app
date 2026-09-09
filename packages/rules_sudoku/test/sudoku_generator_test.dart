import 'package:puzzle_engine/puzzle_engine.dart';
import 'package:rules_sudoku/rules_sudoku.dart';
import 'package:test/test.dart';

void main() {
  const rule = SudokuRule();

  for (final d in Difficulty.values) {
    test('generates a valid unique ${d.name} puzzle', () {
      final p = rule.generate(difficulty: d, seed: 20260909);
      expect(p.size, 9);
      expect(p.givens.length, 81);
      expect(SudokuSolver.isConsistent(p.givens), isTrue);
      expect(SudokuSolver.hasUniqueSolution(p.givens), isTrue);
      expect(SudokuSolver.solve(p.givens), p.solution);
      for (var i = 0; i < 81; i++) {
        if (p.givens[i] != 0) expect(p.givens[i], p.solution[i]);
      }
      expect(p.givenCount, inInclusiveRange(22, 50));
    });
  }

  test('is deterministic for the same seed', () {
    final a = rule.generate(difficulty: Difficulty.medium, seed: 42);
    final b = rule.generate(difficulty: Difficulty.medium, seed: 42);
    expect(a.givens, b.givens);
    expect(a.solution, b.solution);
  });

  test('different seeds give different puzzles', () {
    final a = rule.generate(difficulty: Difficulty.medium, seed: 1);
    final b = rule.generate(difficulty: Difficulty.medium, seed: 2);
    expect(a.givens, isNot(b.givens));
  });

  test('easy puzzles have more clues than expert', () {
    final e = rule.generate(difficulty: Difficulty.easy, seed: 7);
    final x = rule.generate(difficulty: Difficulty.expert, seed: 7);
    expect(e.givenCount, greaterThan(x.givenCount));
  });

  test('rating of generated puzzles matches request most of the time', () {
    var hits = 0;
    const n = 4;
    for (var s = 0; s < n; s++) {
      for (final d in Difficulty.values) {
        final p = rule.generate(difficulty: d, seed: 1000 + s);
        if (SudokuGenerator.rate(p.givens) == d) hits++;
      }
    }
    // Accept the occasional near-miss (rater settles for closest label).
    expect(hits, greaterThanOrEqualTo((n * Difficulty.values.length * 0.7).floor()));
  });

  test('daily seed round trip', () {
    final day = DateTime(2026, 9, 9);
    final seed = DailySeed.forDate(day, salt: 1);
    final a = rule.generate(difficulty: Difficulty.medium, seed: seed);
    final b = rule.generate(difficulty: Difficulty.medium, seed: seed);
    expect(a.id, b.id);
  });

  test('works with GameSession end to end', () {
    final p = rule.generate(difficulty: Difficulty.easy, seed: 3);
    final s = GameSession(puzzle: p, rule: rule);
    // Hints alone must solve any puzzle (logic hints, then reveal fallback).
    var guard = 0;
    while (s.status == GameStatus.playing && guard++ < 100) {
      s.useHint();
    }
    expect(s.status, GameStatus.solved);
  });
}
