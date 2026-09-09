import 'package:puzzle_engine/puzzle_engine.dart';

import 'sudoku_generator.dart';
import 'sudoku_grid.dart';
import 'sudoku_logic_solver.dart';

/// Classic Sudoku as a [PuzzleRule].
class SudokuRule extends PuzzleRule {
  const SudokuRule({this.generator = const SudokuGenerator()});

  final SudokuGenerator generator;

  @override
  String get id => 'sudoku';

  @override
  int get size => SudokuGrid.size;

  @override
  GridPuzzle generate({required Difficulty difficulty, required int seed}) =>
      generator.generate(difficulty: difficulty, seed: seed);

  @override
  List<int> peers(int index) => SudokuGrid.peers[index];

  @override
  List<int> conflicts(List<int> board, int index, int value) => [
        for (final p in SudokuGrid.peers[index])
          if (board[p] == value) p,
      ];

  @override
  Hint? nextHint(List<int> board, GridPuzzle puzzle) {
    // Only explain from a consistent board; if the player has wrong
    // entries, the engine's reveal fallback fixes those first.
    for (var i = 0; i < board.length; i++) {
      if (board[i] != 0 && board[i] != puzzle.solution[i]) return null;
    }
    return SudokuLogicSolver.nextHint(board);
  }
}
