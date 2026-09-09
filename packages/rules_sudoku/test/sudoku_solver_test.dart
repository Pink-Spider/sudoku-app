import 'package:rules_sudoku/rules_sudoku.dart';
import 'package:test/test.dart';

List<int> parse(String s) =>
    s.replaceAll(RegExp(r'[^0-9.]'), '').split('').map((c) => c == '.' ? 0 : int.parse(c)).toList();

/// Well-known "easy" puzzle (Project Euler #96, grid 01).
final easy = parse('''
003020600
900305001
001806400
008102900
700000008
006708200
002609500
800203009
005010300
''');

final easySolution = parse('''
483921657
967345821
251876493
548132976
729564138
136798245
372689514
814253769
695417382
''');

/// Arto Inkala's "world's hardest sudoku" — needs advanced techniques.
final inkala = parse('''
800000000
003600000
070090200
050007000
000045700
000100030
001000068
008500010
090000400
''');

void main() {
  group('SudokuSolver', () {
    test('solves a known puzzle', () {
      expect(SudokuSolver.solve(easy), easySolution);
    });

    test('reports uniqueness', () {
      expect(SudokuSolver.countSolutions(easy), 1);
      expect(SudokuSolver.hasUniqueSolution(easy), isTrue);
    });

    test('empty grid has many solutions', () {
      final empty = List<int>.filled(81, 0);
      expect(SudokuSolver.countSolutions(empty, limit: 5), 5);
    });

    test('detects inconsistent grids', () {
      final bad = List<int>.of(easy)..[1] = 3; // duplicate 3 in row 0
      expect(SudokuSolver.isConsistent(bad), isFalse);
      expect(SudokuSolver.solve(bad), isNull);
    });

    test('solves the hard one too', () {
      final solved = SudokuSolver.solve(inkala);
      expect(solved, isNotNull);
      expect(solved!.contains(0), isFalse);
      expect(SudokuSolver.hasUniqueSolution(inkala), isTrue);
    });
  });

  group('SudokuLogicSolver', () {
    test('solves an easy puzzle with singles only', () {
      final r = SudokuLogicSolver.solve(easy);
      expect(r.solved, isTrue);
      expect(r.maxLevel, lessThanOrEqualTo(2));
      expect(r.board, easySolution);
    });

    test('gets stuck on the hard one', () {
      final r = SudokuLogicSolver.solve(inkala);
      expect(r.solved, isFalse);
      expect(r.maxLevel, 4);
    });

    test('nextHint returns a correct placement', () {
      final h = SudokuLogicSolver.nextHint(easy);
      expect(h, isNotNull);
      expect(easySolution[h!.index], h.value);
      expect(easy[h.index], 0);
    });
  });

  group('SudokuGrid', () {
    test('geometry', () {
      expect(SudokuGrid.units.length, 27);
      expect(SudokuGrid.peers[0].length, 20);
      expect(SudokuGrid.peers[40], contains(31));
      expect(SudokuGrid.boxOf(80), 8);
      expect(SudokuGrid.popCount(SudokuGrid.allValues), 9);
    });
  });
}
