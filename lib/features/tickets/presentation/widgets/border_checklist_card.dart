import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/border_crossing.dart';

/// "Before you cross into Uganda" card with ticked and open requirements.
class BorderChecklistCard extends StatelessWidget {
  const BorderChecklistCard({
    required this.country,
    required this.checks,
    required this.onViewAll,
    super.key,
  });

  final String country;
  final List<BorderCheck> checks;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before you cross into $country',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.palette.text,
            ),
          ),
          for (final check in checks) ...[
            const SizedBox(height: 12),
            _CheckRow(check: check),
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.success,
              alignment: Alignment.centerLeft,
            ),
            child: const Text(
              'View full checklist & station directions →',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});

  final BorderCheck check;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: check.done,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: check.done ? AppColors.success : context.palette.card,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: check.done ? AppColors.success : context.palette.border,
              ),
            ),
            child: check.done
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              check.label,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: context.palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
