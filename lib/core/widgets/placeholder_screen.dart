import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Blank screen used for tabs that teammates will build.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title\nComing soon',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 16)),
      ),
    );
  }
}
