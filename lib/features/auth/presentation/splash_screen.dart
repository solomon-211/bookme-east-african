import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';

/// Shown while Firebase restores the saved session on app start. Same dark
/// background and logo as the Welcome screen, so there is no flash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogo(size: 88, showTagline: false),
              SizedBox(height: 32),
              SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.lime,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
