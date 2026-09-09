import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_engine/puzzle_engine.dart';

import '../game_controller.dart';

/// The 9x9 board. One CustomPainter for the whole grid — far cheaper than
/// 81 widgets and lets highlights repaint in a single pass.
class SudokuBoard extends StatelessWidget {
  const SudokuBoard({
    super.key,
    required this.state,
    required this.rule,
    required this.onCellTap,
  });

  final GameViewState state;
  final PuzzleRule rule;
  final ValueChanged<int> onCellTap;

  @override
  Widget build(BuildContext context) {
    final colors = PuzzleColors.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final cell = side / state.size;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final c = (d.localPosition.dx / cell).floor().clamp(0, state.size - 1);
              final r = (d.localPosition.dy / cell).floor().clamp(0, state.size - 1);
              onCellTap(r * state.size + c);
            },
            child: CustomPaint(
              size: Size.square(side),
              painter: _BoardPainter(
                state: state,
                rule: rule,
                colors: colors,
                textScale: MediaQuery.textScalerOf(context).scale(1),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.state,
    required this.rule,
    required this.colors,
    required this.textScale,
  });

  final GameViewState state;
  final PuzzleRule rule;
  final PuzzleColors colors;
  final double textScale;

  @override
  void paint(Canvas canvas, Size size) {
    final n = state.size;
    final cell = size.width / n;
    final box = _boxSize(n);

    canvas.drawRect(Offset.zero & size, Paint()..color = colors.boardBackground);

    _paintHighlights(canvas, cell);
    _paintValues(canvas, cell);
    _paintGrid(canvas, size, cell, box);
  }

  int _boxSize(int n) {
    for (var b = 3; b >= 2; b--) {
      if (n % b == 0 && b * b == n) return b;
    }
    return n;
  }

  void _paintHighlights(Canvas canvas, double cell) {
    final selected = state.selected;
    final selectedValue = selected == null ? 0 : state.board[selected];
    final peers = selected == null ? const <int>{} : rule.peers(selected).toSet();
    final conflictCells = <int>{};
    for (var i = 0; i < state.board.length; i++) {
      final v = state.board[i];
      if (v == 0) continue;
      if (rule.conflicts(state.board, i, v).isNotEmpty) conflictCells.add(i);
    }

    for (var i = 0; i < state.board.length; i++) {
      Color? fill;
      if (state.hintHighlight.contains(i)) {
        fill = colors.hintHighlight;
      } else if (i == selected) {
        fill = colors.selected;
      } else if (conflictCells.contains(i)) {
        fill = colors.conflict;
      } else if (selectedValue != 0 && state.board[i] == selectedValue) {
        fill = colors.sameValueHighlight;
      } else if (peers.contains(i)) {
        fill = colors.peerHighlight;
      }
      if (fill != null) {
        canvas.drawRect(_rectOf(i, cell), Paint()..color = fill);
      }
    }
    if (selected != null && state.hintHighlight.contains(selected)) {
      canvas.drawRect(
        _rectOf(selected, cell).deflate(1.5),
        Paint()
          ..color = colors.entry
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _paintValues(Canvas canvas, double cell) {
    final valueStyle = TextStyle(
      fontSize: cell * 0.55 * textScale.clamp(0.8, 1.2),
      fontWeight: FontWeight.w500,
    );
    final noteStyle = TextStyle(fontSize: cell * 0.22, color: colors.note);
    final n = state.size;
    final noteCols = _boxSize(n);

    for (var i = 0; i < state.board.length; i++) {
      final rect = _rectOf(i, cell);
      final v = state.board[i];
      if (v != 0) {
        final isGiven = state.puzzle.isGiven(i);
        final wrong = !isGiven && v != state.puzzle.solution[i];
        final color = isGiven
            ? colors.given
            : wrong
                ? colors.entryWrong
                : colors.entry;
        _drawText(canvas, '$v', rect.center, valueStyle.copyWith(color: color));
        continue;
      }
      final notes = state.notes[i];
      if (notes.isEmpty) continue;
      final sub = cell / noteCols;
      for (final note in notes) {
        final k = note - 1;
        final c = k % noteCols, r = k ~/ noteCols;
        final center = Offset(
          rect.left + sub * c + sub / 2,
          rect.top + sub * r + sub / 2,
        );
        _drawText(canvas, '$note', center, noteStyle);
      }
    }
  }

  void _paintGrid(Canvas canvas, Size size, double cell, int box) {
    final thin = Paint()
      ..color = colors.gridLine
      ..strokeWidth = 1;
    final bold = Paint()
      ..color = colors.gridLineBold
      ..strokeWidth = 2.5;
    for (var k = 0; k <= state.size; k++) {
      final p = k * cell;
      final paint = k % box == 0 ? bold : thin;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), paint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), paint);
    }
  }

  Rect _rectOf(int i, double cell) {
    final r = i ~/ state.size, c = i % state.size;
    return Rect.fromLTWH(c * cell, r * cell, cell, cell);
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.state != state || old.colors != colors || old.textScale != textScale;
}
