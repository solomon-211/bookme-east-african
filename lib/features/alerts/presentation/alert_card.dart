import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../domain/app_alert.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    required this.alert,
    required this.timeLabel,
    this.onAction,
    this.onTap,
    super.key,
  });

  final AppAlert alert;
  final String timeLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  static IconData iconFor(AlertKind kind) => switch (kind) {
    AlertKind.delay => Icons.schedule,
    AlertKind.tripCancelled => Icons.cancel_outlined,
    AlertKind.seatOpened => Icons.notifications_active_outlined,
    AlertKind.priceWatch => Icons.trending_down,
    AlertKind.paymentProtected => Icons.lock_outline,
    AlertKind.refundReceived => Icons.highlight_off,
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final urgent = alert.kind.isUrgent;

    final background = urgent ? palette.warningSoft : palette.card;
    final iconColor = urgent ? palette.warningIcon : palette.link;
    final iconBg = urgent
        ? palette.warningIcon.withValues(alpha: 0.18)
        : palette.successSoft;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: urgent
              ? palette.warningIcon.withValues(alpha: 0.25)
              : palette.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(iconFor(alert.kind), size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: alert.read
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: palette.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: TextStyle(fontSize: 11, color: palette.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.body,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: palette.muted,
                      ),
                    ),
                    if (alert.actionLabel != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: onAction,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${alert.actionLabel} →',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: palette.link,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
