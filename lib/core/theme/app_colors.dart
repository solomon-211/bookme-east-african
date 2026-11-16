import 'package:flutter/material.dart';

/// BookMe colour palette.
///
/// Text/background pairs used in the booking screens meet WCAG AA (4.5:1):
/// ink on lime ≈ 15:1, white on ink ≈ 18:1, white on [success] ≈ 5.4:1,
/// [muted] on [surface] ≈ 4.7:1.
class AppColors {
  const AppColors._();

  /// Near-black used for primary buttons and dark trip cards.
  static const Color ink = Color(0xFF0F1712);

  /// Brand lime used for the logo, hold timer and highlights.
  static const Color lime = Color(0xFFD6F25C);
  static const Color limeSoft = Color(0xFFF1FBCB);

  /// Pay button and "verified / protected" accents.
  static const Color success = Color(0xFF1B7A43);
  static const Color successSoft = Color(0xFFE6F4EA);

  static const Color warningSoft = Color(0xFFFFF4DE);
  static const Color warningText = Color(0xFF7A4B00);
  static const Color error = Color(0xFFB3261E);

  /// Page background and card borders.
  static const Color surface = Color(0xFFF3F5F2);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE1E5DF);

  /// Secondary text.
  static const Color muted = Color(0xFF5E6661);
}
