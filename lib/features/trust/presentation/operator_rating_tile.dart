import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../domain/operator_rating.dart';

class OperatorRatingTile extends StatelessWidget {
  const OperatorRatingTile({required this.operator, super.key});

  final OperatorRating operator;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Semantics(
      label:
          '${operator.name}, verified operator, '
          'safety rating ${operator.ratingLabel} out of 5',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    operator.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (operator.verified) const VerifiedBadge(),
                ],
              ),
            ),
            Icon(Icons.star_border_rounded, size: 20, color: palette.text),
            const SizedBox(width: 8),
            Text(
              operator.ratingLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.successSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 13, color: palette.link),
          const SizedBox(width: 5),
          Text(
            'Verified operator',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: palette.link,
            ),
          ),
        ],
      ),
    );
  }
}
