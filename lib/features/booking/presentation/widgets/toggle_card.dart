import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';

/// White rounded card holding one switch, e.g. "Someone else is paying".
///
/// The card colour is painted by a [Material] (not a decorated container)
/// so the ListTile's ink ripple shows on tap.
class ToggleCard extends StatelessWidget {
  const ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.switchKey,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Key on the inner `SwitchListTile`, used by widget tests.
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    );
    return Material(
      color: AppColors.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        key: switchKey,
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.success,
        shape: shape,
        title: Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }
}
