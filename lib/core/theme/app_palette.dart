import 'package:flutter/material.dart';

import 'app_colors.dart';

// Colours that change between light and dark mode. Brand colours that stay
// the same in both (lime, the dark status cards) live in AppColors.
class AppPalette {
  const AppPalette._({
    required this.background,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.iconTile,
    required this.link,
    required this.successSoft,
    required this.warningSoft,
    required this.warningIcon,
  });

  final Color background;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final Color iconTile;
  final Color link; // green "Track automatic refund" style links
  final Color successSoft;
  final Color warningSoft;
  final Color warningIcon;

  static const light = AppPalette._(
    background: AppColors.surface,
    card: AppColors.card,
    text: AppColors.ink,
    muted: AppColors.muted,
    border: AppColors.border,
    iconTile: Color(0xFFEFF2EE),
    link: AppColors.success,
    successSoft: AppColors.successSoft,
    warningSoft: AppColors.warningSoft,
    warningIcon: Color(0xFFB7791F),
  );

  static const dark = AppPalette._(
    background: Color(0xFF0E1411),
    card: Color(0xFF171F1A),
    text: Color(0xFFEEF2EE),
    muted: Color(0xFFA3ACA6),
    border: Color(0xFF2A332D),
    iconTile: Color(0xFF222B25),
    link: Color(0xFF6FD39A),
    successSoft: Color(0xFF15301F),
    warningSoft: Color(0xFF3A2E14),
    warningIcon: Color(0xFFF2C46B),
  );

  // Dark slate behind "Travel with confidence" and the escrow amount.
  // Same in both themes so the lime text always stands out.
  static const statusCard = Color(0xFF1B2125);

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
