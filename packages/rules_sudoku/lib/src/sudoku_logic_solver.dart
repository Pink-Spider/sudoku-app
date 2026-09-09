import 'package:puzzle_engine/puzzle_engine.dart';

import 'sudoku_grid.dart';

/// Solving techniques in ascending order of difficulty. The highest one a
/// puzzle needs determines its rating; the first one that applies to the
/// current board becomes the hint.
enum SudokuTechnique {
  nakedSingle(1, 'naked_single'),
  hiddenSingle(2, 'hidden_single'),
  nakedPair(3, 'naked_pair'),
  pointingPair(3, 'pointing_pair'),
  boxLineReduction(3, 'box_line_reduction');

  const SudokuTechnique(this.level, this.id);

  /// 1 = trivial ... 3 = intermediate. Level 4 is reserved for "stuck":
  /// the puzzle needs techniques this solver does not know (X-wing,
  /// chains, ...) or guessing.
  final int level;

  /// Stable id used by [Hint.techniqueId] and localisation.
  final String id;
}

/// Result of running [SudokuLogicSolver.solve].
class LogicResult {
  const LogicResult({
    required this.solved,
    required this.maxLevel,
    required this.techniques,
    required this.board,
  });

  final bool solved;

  /// Highest technique level used; 4 when the solver got stuck.
  final int maxLevel;

  /// Every technique applied at least once.
  final Set<SudokuTechnique> techniques;

  /// Board state when finished (complete if [solved]).
  final List<int> board;
}

/// A human-style solver: maintains candidate bitmasks and applies
/// techniques from easiest to hardest, exactly like a rating engine.
class SudokuLogicSolver {
  SudokuLogicSolver(List<int> board)
      : _board = List<int>.of(board),
        _cand = List<int>.filled(SudokuGrid.cells, 0) {
    _recomputeCandidates();
  }

  final List<int> _board;
  final List<int> _cand;

  /// Solve as far as pure logic allows.
  static LogicResult solve(List<int> board) {
    final s = SudokuLogicSolver(board);
    final used = <SudokuTechnique>{};
    var maxLevel = 0;
    while (!s._isComplete) {
      final t = s._step();
      if (t == null) {
        return LogicResult(
          solved: false,
          maxLevel: 4,
          techniques: used,
          board: s._board,
        );
      }
      used.add(t);
      if (t.level > maxLevel) maxLevel = t.level;
    }
    return LogicResult(
      solved: true,
      maxLevel: maxLevel,
      techniques: used,
      board: s._board,
    );
  }

  /// The next *placement* a human would make, with an explanation, or
  /// `null` if only eliminations / guessing remain. Eliminations are
  /// applied silently until a placement becomes visible.
  static Hint? nextHint(List<int> board) {
    final s = SudokuLogicSolver(board);
    for (var guard = 0; guard < 50; guard++) {
      final h = s._findNakedSingle() ?? s._findHiddenSingle();
      if (h != null) return h;
      if (!s._eliminate()) return null;
    }
    return null;
  }

  // ------------------------------------------------------------ internals

  bool get _isComplete => !_board.contains(0);

  void _recomputeCandidates() {
    for (var i = 0; i < SudokuGrid.cells; i++) {
      if (_board[i] != 0) {
        _cand[i] = 0;
        continue;
      }
      var used = 0;
      for (final p in SudokuGrid.peers[i]) {
        if (_board[p] != 0) used |= SudokuGrid.bit(_board[p]);
      }
      _cand[i] = SudokuGrid.allValues & ~used;
    }
  }

  void _place(int i, int v) {
    _board[i] = v;
    _cand[i] = 0;
    final b = ~SudokuGrid.bit(v);
    for (final p in SudokuGrid.peers[i]) {
      _cand[p] &= b;
    }
  }

  /// One solving step: place via singles if possible, else eliminate.
  SudokuTechnique? _step() {
    final ns = _findNakedSingle();
    if (ns != null) {
      _place(ns.index, ns.value);
      return SudokuTechnique.nakedSingle;
    }
    final hs = _findHiddenSingle();
    if (hs != null) {
      _place(hs.index, hs.value);
      return SudokuTechnique.hiddenSingle;
    }
    if (_applyNakedPairs()) return SudokuTechnique.nakedPair;
    if (_applyPointingPairs()) return SudokuTechnique.pointingPair;
    if (_applyBoxLineReduction()) return SudokuTechnique.boxLineReduction;
    return null;
  }

  bool _eliminate() =>
      _applyNakedPairs() || _applyPointingPairs() || _applyBoxLineReduction();

  Hint? _findNakedSingle() {
    for (var i = 0; i < SudokuGrid.cells; i++) {
      if (_board[i] == 0 && SudokuGrid.popCount(_cand[i]) == 1) {
        return Hint(
          index: i,
          value: SudokuGrid.singleValue(_cand[i]),
          techniqueId: SudokuTechnique.nakedSingle.id,
          highlight: SudokuGrid.peers[i],
        );
      }
    }
    return null;
  }

  Hint? _findHiddenSingle() {
    for (final unit in SudokuGrid.units) {
      for (var v = 1; v <= SudokuGrid.size; v++) {
        final b = SudokuGrid.bit(v);
        var where = -1, n = 0;
        for (final i in unit) {
          if (_cand[i] & b != 0) {
            where = i;
            if (++n > 1) break;
          }
        }
        if (n == 1) {
          return Hint(
            index: where,
            value: v,
            techniqueId: SudokuTechnique.hiddenSingle.id,
            highlight: unit,
          );
        }
      }
    }
    return null;
  }

  /// Two cells in a unit sharing the same two candidates → remove those
  /// candidates from every other cell in the unit.
  bool _applyNakedPairs() {
    var changed = false;
    for (final unit in SudokuGrid.units) {
      for (var a = 0; a < unit.length; a++) {
        final ca = _cand[unit[a]];
        if (SudokuGrid.popCount(ca) != 2) continue;
        for (var b = a + 1; b < unit.length; b++) {
          if (_cand[unit[b]] != ca) continue;
          for (final i in unit) {
            if (i == unit[a] || i == unit[b]) continue;
            if (_cand[i] & ca != 0) {
              _cand[i] &= ~ca;
              changed = true;
            }
          }
        }
      }
    }
    return changed;
  }

  /// Within a box, if all candidates for v lie in one row (or column),
  /// v cannot appear elsewhere in that row (column).
  bool _applyPointingPairs() {
    var changed = false;
    for (var bx = 0; bx < SudokuGrid.size; bx++) {
      final unit = SudokuGrid.units[2 * SudokuGrid.size + bx];
      for (var v = 1; v <= SudokuGrid.size; v++) {
        final b = SudokuGrid.bit(v);
        final cellsWithV = [for (final i in unit) if (_cand[i] & b != 0) i];
        if (cellsWithV.length < 2) continue;
        final rows = cellsWithV.map(SudokuGrid.row).toSet();
        final cols = cellsWithV.map(SudokuGrid.col).toSet();
        if (rows.length == 1) {
          for (final i in SudokuGrid.units[rows.first]) {
            if (SudokuGrid.boxOf(i) != bx && _cand[i] & b != 0) {
              _cand[i] &= ~b;
              changed = true;
            }
          }
        } else if (cols.length == 1) {
          for (final i in SudokuGrid.units[SudokuGrid.size + cols.first]) {
            if (SudokuGrid.boxOf(i) != bx && _cand[i] & b != 0) {
              _cand[i] &= ~b;
              changed = true;
            }
          }
        }
      }
    }
    return changed;
  }

  /// Within a row (or column), if all candidates for v lie in one box,
  /// v cannot appear elsewhere in that box.
  bool _applyBoxLineReduction() {
    var changed = false;
    for (var u = 0; u < 2 * SudokuGrid.size; u++) {
      final line = SudokuGrid.units[u];
      for (var v = 1; v <= SudokuGrid.size; v++) {
        final b = SudokuGrid.bit(v);
        final cellsWithV = [for (final i in line) if (_cand[i] & b != 0) i];
        if (cellsWithV.length < 2) continue;
        final boxes = cellsWithV.map(SudokuGrid.boxOf).toSet();
        if (boxes.length != 1) continue;
        final boxUnit = SudokuGrid.units[2 * SudokuGrid.size + boxes.first];
        for (final i in boxUnit) {
          if (!line.contains(i) && _cand[i] & b != 0) {
            _cand[i] &= ~b;
            changed = true;
          }
        }
      }
    }
    return changed;
  }
}
