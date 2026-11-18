import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';

enum InfoNoteTone { protected, caution, highlight }

/// Coloured callout box: the green "Your money. Protected." escrow note,
/// the amber "Never charged twice" note, or a lime highlight.
class InfoNote extends StatelessWidget {
  const InfoNote({
    required this.message,
    this.title,
    this.icon,
    this.tone = InfoNoteTone.protected,
    super.key,
  });

  final String? title;
  final String message;
  final IconData? icon;
  final InfoNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final (
      Color bg,
      Color accent,
      Color text,
      IconData defaultIcon,
    ) = switch (tone) {
      InfoNoteTone.protected => (
        AppColors.successSoft,
        AppColors.success,
        AppColors.ink,
        Icons.verified_user_outlined,
      ),
      InfoNoteTone.caution => (
        AppColors.warningSoft,
        AppColors.warningText,
        AppColors.warningText,
        Icons.shield_outlined,
      ),
      InfoNoteTone.highlight => (
        AppColors.lime,
        AppColors.ink,
        AppColors.ink,
        Icons.info_outline,
      ),
    };
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(color: text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
