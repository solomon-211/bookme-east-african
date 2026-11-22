import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';

/// Page frame shared by the booking screens.
///
/// * The body scrolls, so nothing overflows in landscape or on 5" phones.
/// * Content is capped at [maxContentWidth] and centred, so it doesn't
///   stretch awkwardly on large phones and tablets.
/// * [bottom] holds the main action and stays pinned above the home bar.
class FlowScaffold extends StatelessWidget {
  const FlowScaffold({
    required this.title,
    required this.children,
    this.subtitle,
    this.bottom,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? bottom;

  static const double maxContentWidth = 560;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: canPop ? 0 : 16,
        automaticallyImplyLeading: false,
        leading: canPop ? const BackButton(color: AppColors.ink) : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: children,
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: bottom,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Small grey label above a group of fields, e.g. "Pay with".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
