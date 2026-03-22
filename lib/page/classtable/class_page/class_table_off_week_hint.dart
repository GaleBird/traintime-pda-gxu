// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class ClassTableOffWeekHint extends StatelessWidget {
  static const double _iconSize = 14;
  static const double _radius = 999;
  static const double _borderAlphaLight = 0.18;
  static const double _borderAlphaDark = 0.34;
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(9, 5, 10, 5);

  const ClassTableOffWeekHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = scheme.error.withValues(
      alpha: isDark ? _borderAlphaDark : _borderAlphaLight,
    );
    final backgroundColor = Color.alphaBlend(
      scheme.error.withValues(alpha: isDark ? 0.16 : 0.1),
      scheme.surfaceContainerHighest,
    );
    final foregroundColor = Color.alphaBlend(
      scheme.error.withValues(alpha: 0.82),
      scheme.onSurface,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: _padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: _iconSize,
              color: foregroundColor,
            ),
            const SizedBox(width: 4),
            Text(
              FlutterI18n.translate(
                context,
                "classtable.week_hint.not_current_week",
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassTableOffWeekAction extends StatelessWidget {
  final ValueNotifier<int> visibleWeekListenable;
  final int currentWeek;

  const ClassTableOffWeekAction({
    super.key,
    required this.visibleWeekListenable,
    required this.currentWeek,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: visibleWeekListenable,
      builder: (context, weekIndex, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: weekIndex != currentWeek
              ? const Padding(
                  key: ValueKey("off_week_hint"),
                  padding: EdgeInsetsDirectional.only(end: 6),
                  child: Center(child: ClassTableOffWeekHint()),
                )
              : const SizedBox.shrink(key: ValueKey("off_week_hint_hidden")),
        );
      },
    );
  }
}
