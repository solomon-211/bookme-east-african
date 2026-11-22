import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

// Grey safety box, e.g. "BookMe will never ask for your MoMo PIN".
class AuthNote extends StatelessWidget {
  const AuthNote({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.iconTile,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.text),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Small grey label above a group of inputs, e.g. "Country code".
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, color: AppPalette.of(context).muted),
      ),
    );
  }
}
