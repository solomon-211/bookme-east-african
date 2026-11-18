import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';

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
    final foreground = style == PrimaryButtonStyle.outlined
        ? AppColors.ink
        : Colors.white;
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
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.2),
          backgroundColor: Colors.white,
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
        backgroundColor: style == PrimaryButtonStyle.success
            ? AppColors.success
            : AppColors.ink,
        disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white,
      ),
      child: child,
    );
  }
}
