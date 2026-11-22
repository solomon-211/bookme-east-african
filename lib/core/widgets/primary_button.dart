import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Full-width dark pill used for the main action on the auth screens
// ("Send OTP", "Verify and Continue", "Sign in"). Lime in dark mode so it
// keeps its contrast. 54px high, above Material's 48px tap target.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.arrow_forward,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  // Shown after the label; null hides it.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? AppColors.lime : AppColors.ink;
    final foreground = dark ? AppColors.ink : Colors.white;

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.5),
        disabledForegroundColor: foreground,
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
      ),
      child: isLoading
          ? SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: foreground,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 18),
                ],
              ],
            ),
    );
  }
}
