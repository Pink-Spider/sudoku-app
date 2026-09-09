import 'dart:math';

import 'package:puzzle_engine/puzzle_engine.dart';

import 'sudoku_grid.dart';
import 'sudoku_logic_solver.dart';
import 'sudoku_solver.dart';

/// Target clue counts per difficulty. Ranges overlap deliberately: the
/// final label comes from [rate], not from the count alone.
class _Target {
  const _Target(this.minClues, this.maxClues);
  final int minClues;
  final int maxClues;
}

const Map<Difficulty, _Target> _targets = {
  Difficulty.easy: _Target(38, 44),
  Difficulty.medium: _Target(31, 36),
  Difficulty.hard: _Target(26, 30),
  Difficulty.expert: _Target(22, 26),
};

/// Deterministic Sudoku generator.
///
/// `generate(difficulty, seed)` always returns the same puzzle for the same
/// arguments (across devices and app versions, as long as this file does
/// not change — bump [algorithmVersion] if it ever does, and mix it into
/// the daily seed salt so old daily puzzles are not silently replaced).
class SudokuGenerator {
  const SudokuGenerator({this.maxAttempts = 24});

  static const int algorithmVersion = 1;

  /// How many differently-seeded attempts to make before settling for the
  /// closest rating.
  final int maxAttempts;

  /// Rate an arbitrary puzzle (givens, `0` = empty).
  static Difficulty rate(List<int> givens) {
    final result = SudokuLogicSolver.solve(givens);
    final clues = givens.where((v) => v != 0).length;
    if (!result.solved || result.maxLevel >= 4) return Difficulty.expert;
    if (result.maxLevel == 3) return Difficulty.hard;
    return clues >= 36 ? Difficulty.easy : Difficulty.medium;
  }

  GridPuzzle generate({required Difficulty difficulty, required int seed}) {
    List<int>? bestGivens;
    List<int>? bestSolution;
    var bestDistance = 1 << 30;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rng = Random(_mix(seed, attempt));
      final solution = fullGrid(rng);
      final givens = _carve(solution, difficulty, rng);
      final rating = rate(givens);
      final distance = (rating.index - difficulty.index).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestGivens = givens;
        bestSolution = solution;
        if (distance == 0) break;
      }
    }

    return GridPuzzle(
      ruleId: 'sudoku',
      size: SudokuGrid.size,
      givens: bestGivens!,
      solution: bestSolution!,
      difficulty: difficulty,
      seed: seed,
    );
  }

  /// A random complete, valid grid.
  static List<int> fullGrid(Random rng) {
    final empty = List<int>.filled(SudokuGrid.cells, 0);
    // Seed the first row with a permutation so the search starts random
    // even before the solver shuffles candidates.
    final firstRow = List<int>.generate(SudokuGrid.size, (i) => i + 1)
      ..shuffle(rng);
    for (var c = 0; c < SudokuGrid.size; c++) {
      empty[c] = firstRow[c];
    }
    return SudokuSolver.solve(empty, random: rng)!;
  }

  /// Remove clues from [solution] (180° symmetric pairs) while the puzzle
  /// stays uniquely solvable, until the clue count enters the target
  /// range for [difficulty] or no further removal is possible.
  static List<int> _carve(List<int> solution, Difficulty difficulty, Random rng) {
    final target = _targets[difficulty]!;
    final givens = List<int>.of(solution);
    var clues = SudokuGrid.cells;

    // Visit each symmetric pair once, in random order.
    final order = List<int>.generate(SudokuGrid.cells, (i) => i)..shuffle(rng);
    final visited = List<bool>.filled(SudokuGrid.cells, false);

    for (final i in order) {
      if (clues <= target.minClues) break;
      if (visited[i]) continue;
      final j = SudokuGrid.cells - 1 - i;
      visited[i] = true;
      visited[j] = true;

      final a = givens[i], b = givens[j];
      givens[i] = 0;
      final removing = i == j ? 1 : 2;
      if (i != j) givens[j] = 0;

      if (clues - removing < target.minClues ||
          !SudokuSolver.hasUniqueSolution(givens)) {
        // Try removing just one of the pair before giving up on it.
        givens[i] = a;
        givens[j] = b;
        if (i != j && clues - 1 >= target.minClues) {
          givens[i] = 0;
          if (SudokuSolver.hasUniqueSolution(givens)) {
            clues -= 1;
            continue;
          }
          givens[i] = a;
        }
        continue;
      }
      clues -= removing;
    }
    // Overshoot protection: if we are above maxClues (grid resisted
    // removal) that is acceptable — the rater decides the label.
    assert(clues >= target.minClues);
    return givens;
  }

  static int _mix(int seed, int attempt) {
    var x = (seed ^ (attempt * 0x9E3779B1) ^ (algorithmVersion << 24)) &
        0x7fffffff;
    x = ((x ^ (x >> 15)) * 0x2c1b3c6d) & 0x7fffffff;
    x = ((x ^ (x >> 12)) * 0x297a2d39) & 0x7fffffff;
    return x ^ (x >> 15);
  }
}
