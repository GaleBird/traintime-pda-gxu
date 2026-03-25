import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

const gxuNetworkPrimaryActionColor = Color(0xFF355E95);

class GxuNetworkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const GxuNetworkActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1.1,
    );
    final contentTextStyle = filled
        ? textStyle?.copyWith(color: Colors.white)
        : textStyle;
    final style = filled
        ? FilledButton.styleFrom(
            backgroundColor: gxuNetworkPrimaryActionColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: textStyle,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: filled ? Colors.white : null),
        const SizedBox(width: 6),
        Flexible(
          child: AutoSizeText(
            label,
            maxLines: 1,
            minFontSize: 9,
            stepGranularity: 0.5,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: contentTextStyle,
          ),
        ),
      ],
    );

    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: content)
        : OutlinedButton(onPressed: onPressed, style: style, child: content);
  }
}
