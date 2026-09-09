import 'package:flutter/material.dart';

/// 1..N input row. A digit that already appears N times is greyed out.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.maxValue,
    required this.countOf,
    required this.onTap,
    required this.enabled,
  });

  final int maxValue;
  final int Function(int value) countOf;
  final ValueChanged<int> onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var v = 1; v <= maxValue; v++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AspectRatio(
                aspectRatio: 0.8,
                child: Material(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: enabled && countOf(v) < maxValue ? () => onTap(v) : null,
                    child: Center(
                      child: Text(
                        '$v',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: countOf(v) >= maxValue
                                  ? scheme.outlineVariant
                                  : scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
