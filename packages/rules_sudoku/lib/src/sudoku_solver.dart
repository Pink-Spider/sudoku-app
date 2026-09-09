import 'dart:math';

import 'sudoku_grid.dart';

/// Bitmask backtracking solver with most-constrained-cell ordering.
///
/// Fast enough to run uniqueness checks dozens of times per generated
/// puzzle on-device (well under a millisecond each for typical grids).
class SudokuSolver {
  SudokuSolver._(this._grid)
      : _rows = List<int>.filled(SudokuGrid.size, 0),
        _cols = List<int>.filled(SudokuGrid.size, 0),
        _boxes = List<int>.filled(SudokuGrid.size, 0);

  final List<int> _grid;
  final List<int> _rows;
  final List<int> _cols;
  final List<int> _boxes;

  /// Solve a copy of [grid] (`0` = empty). Returns the solved grid, or
  /// `null` if unsolvable. When [random] is given, candidate order is
  /// shuffled — used to generate random full grids from an empty board.
  static List<int>? solve(List<int> grid, {Random? random}) {
    final s = SudokuSolver._(List<int>.of(grid));
    if (!s._init()) return null;
    return s._search(random) ? s._grid : null;
  }

  /// Number of solutions of [grid], capped at [limit] (default 2, which is
  /// all a uniqueness check needs).
  static int countSolutions(List<int> grid, {int limit = 2}) {
    final s = SudokuSolver._(List<int>.of(grid));
    if (!s._init()) return 0;
    return s._count(limit);
  }

  static bool hasUniqueSolution(List<int> grid) =>
      countSolutions(grid, limit: 2) == 1;

  /// True if [grid] has no rule violations among filled cells.
  static bool isConsistent(List<int> grid) => SudokuSolver._(grid)._init();

  bool _init() {
    for (var i = 0; i < SudokuGrid.cells; i++) {
      final v = _grid[i];
      if (v == 0) continue;
      final b = SudokuGrid.bit(v);
      final r = SudokuGrid.row(i), c = SudokuGrid.col(i), x = SudokuGrid.boxOf(i);
      if ((_rows[r] | _cols[c] | _boxes[x]) & b != 0) return false;
      _rows[r] |= b;
      _cols[c] |= b;
      _boxes[x] |= b;
    }
    return true;
  }

  int _candidates(int i) {
    final used = _rows[SudokuGrid.row(i)] |
        _cols[SudokuGrid.col(i)] |
        _boxes[SudokuGrid.boxOf(i)];
    return SudokuGrid.allValues & ~used;
  }

  /// Empty cell with the fewest candidates, or -1 if the grid is full.
  /// Returns -2 if some empty cell has no candidates (dead end).
  int _pickCell() {
    var best = -1, bestCount = 10;
    for (var i = 0; i < SudokuGrid.cells; i++) {
      if (_grid[i] != 0) continue;
      final n = SudokuGrid.popCount(_candidates(i));
      if (n == 0) return -2;
      if (n < bestCount) {
        best = i;
        bestCount = n;
        if (n == 1) break;
      }
    }
    return best;
  }

  void _set(int i, int v) {
    final b = SudokuGrid.bit(v);
    _grid[i] = v;
    _rows[SudokuGrid.row(i)] |= b;
    _cols[SudokuGrid.col(i)] |= b;
    _boxes[SudokuGrid.boxOf(i)] |= b;
  }

  void _unset(int i, int v) {
    final b = ~SudokuGrid.bit(v);
    _grid[i] = 0;
    _rows[SudokuGrid.row(i)] &= b;
    _cols[SudokuGrid.col(i)] &= b;
    _boxes[SudokuGrid.boxOf(i)] &= b;
  }

  bool _search(Random? random) {
    final i = _pickCell();
    if (i == -1) return true;
    if (i == -2) return false;
    final values = SudokuGrid.valuesOf(_candidates(i));
    if (random != null) values.shuffle(random);
    for (final v in values) {
      _set(i, v);
      if (_search(random)) return true;
      _unset(i, v);
    }
    return false;
  }

  int _count(int limit) {
    final i = _pickCell();
    if (i == -1) return 1;
    if (i == -2) return 0;
    var total = 0;
    for (final v in SudokuGrid.valuesOf(_candidates(i))) {
      _set(i, v);
      total += _count(limit - total);
      _unset(i, v);
      if (total >= limit) return total;
    }
    return total;
  }
}
