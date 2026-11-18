import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/escrow_record.dart';

// Vertical list of steps joined by a thin line:
// green check = done, lime check = latest, grey = still to come.
class EscrowTimeline extends StatelessWidget {
  const EscrowTimeline({required this.steps, super.key});

  final List<EscrowStep> steps;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepRow(step: steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final EscrowStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final upcoming = step.state == EscrowStepState.upcoming;

    return Semantics(
      label:
          '${step.title}. ${upcoming ? 'Not yet' : 'Complete'}. '
          '${step.description}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  _StepDot(step: step),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: palette.border,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: upcoming ? palette.muted : palette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.step});

  final EscrowStep step;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    final (Color bg, Color fg) = switch (step.state) {
      EscrowStepState.done => (AppColors.success, Colors.white),
      EscrowStepState.current => (AppColors.lime, AppColors.ink),
      EscrowStepState.upcoming => (palette.iconTile, palette.muted),
    };

    // Finished steps show a tick; the boarding step shows a scanner
    // until it happens.
    final IconData icon;
    if (step.icon == StepIcon.refund) {
      icon = Icons.replay;
    } else if (step.state != EscrowStepState.upcoming) {
      icon = Icons.check;
    } else if (step.icon == StepIcon.boarding) {
      icon = Icons.qr_code_scanner;
    } else {
      icon = Icons.more_horiz;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 15, color: fg),
    );
  }
}
