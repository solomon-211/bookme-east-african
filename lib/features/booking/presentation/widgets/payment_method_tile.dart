import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';

/// One selectable row in the "Pay with" list.
///
/// Drawn by hand instead of using `Radio`, whose `groupValue` API is
/// deprecated in recent Flutter. Semantics still announce it as a selected
/// option in a group for screen readers.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        selected: selected,
        button: true,
        label: '${method.label}, ${method.subtitle}',
        excludeSemantics: true,
        child: Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? AppColors.ink : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: InkWell(
            key: ValueKey('method-${method.name}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _MethodLogo(method),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.label,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            method.subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        key: ValueKey(selected),
                        color: selected ? AppColors.ink : AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Coloured square standing in for each provider's logo.
class _MethodLogo extends StatelessWidget {
  const _MethodLogo(this.method);

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String text) = switch (method) {
      PaymentMethod.mtnMomo => (const Color(0xFFFFCC00), AppColors.ink, 'MoMo'),
      PaymentMethod.mpesa => (const Color(0xFF007A3D), Colors.white, 'M-PESA'),
      PaymentMethod.airtelMoney => (
        const Color(0xFFD50000),
        Colors.white,
        'airtel',
      ),
      PaymentMethod.card => (AppColors.ink, Colors.white, 'VISA'),
    };
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
