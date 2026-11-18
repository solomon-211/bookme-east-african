import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/refund_policy.dart';

// The white card with the green headline and the three rule sections.
// Shown inside the Trust Center and on its own as the Refund policy screen.
class RefundPolicyCard extends StatelessWidget {
  const RefundPolicyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            RefundPolicy.headline,
            style: TextStyle(
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: palette.link,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            RefundPolicy.summary,
            style: TextStyle(fontSize: 13.5, height: 1.4, color: palette.text),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: palette.border),
          ),
          for (final (i, section) in RefundPolicy.sections.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            Text(
              section.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: palette.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
