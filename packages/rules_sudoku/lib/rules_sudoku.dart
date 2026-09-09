/// Classic 9x9 Sudoku for `puzzle_engine`.
///
/// * [SudokuSolver]      — fast bitmask backtracking; solves and counts
///                         solutions (uniqueness check).
/// * [SudokuLogicSolver] — solves the way a human does (singles, pairs,
///                         pointing); used for difficulty rating and hints.
/// * [SudokuGenerator]   — deterministic (seeded) puzzle generation.
/// * [SudokuRule]        — the `PuzzleRule` the app talks to.
library;

export 'src/sudoku_generator.dart';
export 'src/sudoku_grid.dart';
export 'src/sudoku_logic_solver.dart';
export 'src/sudoku_rule.dart';
export 'src/sudoku_solver.dart';
