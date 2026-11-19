import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';

/// A white row with an icon, a title, a one-line explanation and a chevron.
/// The "Menu item" of the design, used on the ticket and Manage Booking.
class MenuTile extends StatelessWidget {
  const MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEFEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
