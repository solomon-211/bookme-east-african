import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

// Rounded chip: black when selected, outlined when not. Used for the
// alert filters and the language / theme choices.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? AppColors.lime : AppColors.ink;
    final selectedFg = isDark ? AppColors.ink : Colors.white;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? selectedBg : palette.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? selectedBg : palette.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? selectedFg : palette.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
