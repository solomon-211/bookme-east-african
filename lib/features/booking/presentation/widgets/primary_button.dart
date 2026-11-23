import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';

enum PrimaryButtonStyle { dark, success, outlined }

/// Full-width pill button used for every main action in the flow.
///
/// Height is 52 logical pixels, above Material's 48dp minimum tap target.
/// While [loading] is true the button shows a spinner and ignores taps.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.style = PrimaryButtonStyle.dark,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final PrimaryButtonStyle style;

  @override
  Widget build(BuildContext context) {
    // Ink in light mode, lime in dark mode (green stays green for "Pay").
    final palette = context.palette;
    final success = style == PrimaryButtonStyle.success;
    final foreground = switch (style) {
      PrimaryButtonStyle.outlined => palette.text,
      _ when success => Colors.white,
      _ => palette.onAccent,
    };
    final child = loading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: foreground,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18),
              ],
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    const size = Size.fromHeight(52);
    final action = loading ? null : onPressed;

    if (style == PrimaryButtonStyle.outlined) {
      return OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          shape: shape,
          foregroundColor: palette.text,
          side: BorderSide(color: palette.text, width: 1.2),
          backgroundColor: palette.card,
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(
        minimumSize: size,
        shape: shape,
        foregroundColor: foreground,
        backgroundColor: success ? AppColors.success : palette.accent,
        disabledBackgroundColor: palette.accent.withValues(alpha: 0.35),
        disabledForegroundColor: palette.onAccent,
      ),
      child: child,
    );
  }
}
