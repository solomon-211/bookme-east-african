import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// The lime "B" tile with "bookme" and the tagline under it.
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 88, this.showTagline = true, super.key});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BookMe. A better way across borders.',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(size * 0.24),
            ),
            child: Text(
              'B',
              style: TextStyle(
                fontSize: size * 0.55,
                height: 1,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          SizedBox(height: size * 0.14),
          Text(
            'bookme',
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
              color: AppColors.lime,
            ),
          ),
          if (showTagline) ...[
            const SizedBox(height: 4),
            const Text(
              'A better way across borders.',
              style: TextStyle(fontSize: 12.5, color: AppColors.lime),
            ),
          ],
        ],
      ),
    );
  }
}
