import 'package:flutter/material.dart';

/// One size for every full-width control on the auth screens:
/// buttons and the phone number field share the same height and corner radius.
const double kControlHeight = 52;
const double kControlRadius = 12;

/// Button style with squared-off corners (small radius, never a pill).
/// Overrides whatever the app theme says about button shape.
ButtonStyle controlButtonStyle({Color? background, Color? foreground}) {
  return FilledButton.styleFrom(
    backgroundColor: background,
    foregroundColor: foreground,
    minimumSize: const Size.fromHeight(kControlHeight),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kControlRadius),
    ),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}
