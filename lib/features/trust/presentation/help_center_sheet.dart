import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

// Short answers to the questions travellers ask most. Opened from the
// Account screen and the Trust Center.
Future<void> showHelpCenter(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _HelpCenterSheet(),
  );
}

class _HelpCenterSheet extends StatelessWidget {
  const _HelpCenterSheet();

  static const _topics = [
    (
      Icons.payments_outlined,
      'Payments',
      'Approve the MoMo prompt on your own phone. BookMe will never ask for '
          'your PIN by call or SMS. If a payment fails you are never charged '
          'twice; check the status before trying again.',
    ),
    (
      Icons.qr_code_2,
      'Boarding',
      'Arrive 30 minutes early and show your QR ticket. It works offline. '
          'Your money is released to the operator only after your boarding '
          'is scanned and verified.',
    ),
    (
      Icons.flag_outlined,
      'Crossing the border',
      'Carry the passport or EAC ID you booked with, a yellow fever card, '
          'and any visa your nationality needs. Check the cross-border '
          'checklist in My Trips before you travel.',
    ),
    (
      Icons.replay,
      'Refunds',
      'Operator cancellations and delays over 2 hours are refunded in full, '
          'automatically, to the number or card you paid with. Progress is '
          'shown in Alerts.',
    ),
    (
      Icons.health_and_safety_outlined,
      'Safety concern',
      'If you feel unsafe on a trip, contact local emergency services first '
          '(112 in Rwanda, 999 in Uganda and Kenya). Then report the operator '
          'from Manage booking so we can follow up.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            'Help Center',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Payments, boarding and border guidance',
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
          const SizedBox(height: 12),
          for (final (icon, title, body) in _topics)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              leading: Icon(icon, color: palette.text),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
              childrenPadding: const EdgeInsets.only(left: 40, bottom: 12),
              children: [
                Text(body, style: TextStyle(height: 1.4, color: palette.muted)),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            'Never share a PIN or OTP with anyone, including BookMe support.',
            style: TextStyle(fontSize: 12.5, color: palette.muted),
          ),
        ],
      ),
    );
  }
}
