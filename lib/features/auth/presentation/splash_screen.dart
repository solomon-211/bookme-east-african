import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shown while Firebase restores the saved session on app start.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.success,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_rounded, size: 64, color: Colors.white),
            SizedBox(height: 16),
            CircularProgressIndicator(color: AppColors.lime),
          ],
        ),
      ),
    );
  }
}
