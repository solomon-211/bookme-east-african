import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/seat_hold_cubit.dart';

/// The lime "seat held" banner with a live mm:ss countdown.
///
/// It rebuilds from [SeatHoldCubit], so the same countdown shows on every
/// booking screen. Under two minutes the time turns red to warn the user.
class HoldTimerBanner extends StatelessWidget {
  const HoldTimerBanner({
    this.title,
    this.subtitle = 'Complete payment before the timer ends',
    this.showProgress = false,
    super.key,
  });

  /// Defaults to "Seat 4C held for 10 minutes".
  final String? title;
  final String subtitle;
  final bool showProgress;

  static const Duration _warnBelow = Duration(minutes: 2);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeatHoldCubit, SeatHoldState>(
      builder: (context, state) {
        final textTheme = Theme.of(context).textTheme;
        final holding = state.status == SeatHoldStatus.holding;
        final seat = state.booking?.seatNumber;
        final heading = holding
            ? 'Holding a seat for you…'
            : title ?? 'Seat ${seat ?? ''} held for 10 minutes';
        final warn =
            state.remaining < _warnBelow &&
            state.status == SeatHoldStatus.active;
        final countdown = Formatters.countdown(state.remaining);

        return Semantics(
          container: true,
          label: holding
              ? heading
              : '$heading. ${state.remaining.inMinutes} minutes '
                    '${state.remaining.inSeconds % 60} seconds left.',
          excludeSemantics: true,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: AppColors.ink,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              heading,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (holding)
                        const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.ink,
                          ),
                        )
                      else
                        Text(
                          countdown,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: warn ? AppColors.error : AppColors.ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
                if (showProgress)
                  LinearProgressIndicator(
                    value: holding ? null : state.progress,
                    minHeight: 4,
                    color: AppColors.ink,
                    backgroundColor: AppColors.ink.withValues(alpha: 0.12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
