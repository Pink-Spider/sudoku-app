/// Static geometry of a 9x9 Sudoku grid. Precomputed once.
class SudokuGrid {
  const SudokuGrid._();

  static const int size = 9;
  static const int box = 3;
  static const int cells = 81;

  /// Bitmask with bits 1..9 set (bit 0 unused).
  static const int allValues = 0x3FE;

  static int row(int i) => i ~/ size;
  static int col(int i) => i % size;
  static int boxOf(int i) => (row(i) ~/ box) * box + col(i) ~/ box;
  static int index(int r, int c) => r * size + c;

  /// 27 units (9 rows, 9 cols, 9 boxes), each a list of 9 indices.
  static final List<List<int>> units = _buildUnits();

  /// For every cell, the 20 cells sharing a row, column or box.
  static final List<List<int>> peers = _buildPeers();

  /// For every cell, the three unit ids it belongs to (row, col, box).
  static List<int> unitsOf(int i) => [row(i), size + col(i), 2 * size + boxOf(i)];

  static List<List<int>> _buildUnits() {
    final u = <List<int>>[];
    for (var r = 0; r < size; r++) {
      u.add([for (var c = 0; c < size; c++) index(r, c)]);
    }
    for (var c = 0; c < size; c++) {
      u.add([for (var r = 0; r < size; r++) index(r, c)]);
    }
    for (var b = 0; b < size; b++) {
      final r0 = (b ~/ box) * box, c0 = (b % box) * box;
      u.add([
        for (var r = r0; r < r0 + box; r++)
          for (var c = c0; c < c0 + box; c++) index(r, c),
      ]);
    }
    return List.unmodifiable(u.map(List<int>.unmodifiable));
  }

  static List<List<int>> _buildPeers() {
    final p = <List<int>>[];
    for (var i = 0; i < cells; i++) {
      final set = <int>{};
      for (final u in unitsOf(i)) {
        set.addAll(units[u]);
      }
      set.remove(i);
      p.add(List<int>.unmodifiable(set.toList()..sort()));
    }
    return List.unmodifiable(p);
  }

  static bool isValidValue(int v) => v >= 1 && v <= size;

  static int bit(int v) => 1 << v;

  static int popCount(int mask) {
    var n = 0;
    while (mask != 0) {
      mask &= mask - 1;
      n++;
    }
    return n;
  }

  /// Values contained in a bitmask, ascending.
  static List<int> valuesOf(int mask) => [
        for (var v = 1; v <= size; v++)
          if (mask & bit(v) != 0) v,
      ];

  /// The single value in a one-bit mask.
  static int singleValue(int mask) {
    for (var v = 1; v <= size; v++) {
      if (mask == bit(v)) return v;
    }
    throw ArgumentError('mask $mask is not a single value');
  }
}
