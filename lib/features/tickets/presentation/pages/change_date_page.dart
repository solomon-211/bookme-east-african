import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/date_change.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/change_date_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/page_header.dart';

/// "Change date / time": pick another departure on the same route.
/// Closes with the moved [Ticket], or `null` if nothing changed. Needs a
/// [TicketsRepository] above it.
class ChangeDatePage extends StatelessWidget {
  const ChangeDatePage({required this.ticket, this.clock, super.key});

  final Ticket ticket;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChangeDateCubit(
        repository: ctx.read<TicketsRepository>(),
        ticket: ticket,
        clock: clock,
      )..load(),
      child: const ChangeDateView(),
    );
  }
}

/// The screen itself, separate from [ChangeDatePage] so tests can supply
/// their own cubit.
class ChangeDateView extends StatelessWidget {
  const ChangeDateView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangeDateCubit, ChangeDateState>(
      listenWhen: (before, after) =>
          before.status != after.status || before.message != after.message,
      listener: (context, state) {
        final changed = state.changed;
        if (state.status == ChangeDateStatus.changed && changed != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Moved to ${_when(changed.trip)} · Seat '
                '${changed.booking.seatNumber}.',
              ),
            ),
          );
          Navigator.of(context).pop(changed);
          return;
        }
        final message = state.message;
        if (message != null && state.status != ChangeDateStatus.failed) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<ChangeDateCubit>();
        final ticket = cubit.ticket;
        final selected = state.selected;
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Change date / time',
                  subtitle:
                      '${ticket.trip.fromCode} → ${ticket.trip.toCode} · '
                      'now ${_when(ticket.trip)}',
                ),
                Expanded(child: _Body(state: state)),
                if (state.trips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: PrimaryButton(
                      label: selected == null
                          ? 'Pick a departure'
                          : 'Move to ${_when(selected)}',
                      loading: state.isChanging,
                      onPressed: selected == null
                          ? null
                          : () => _confirmMove(context, selected),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmMove(BuildContext context, TripSummary trip) async {
    final cubit = context.read<ChangeDateCubit>();
    final quote = cubit.quoteFor(trip);
    if (quote == null) return;
    final money = Formatters.money(quote.refund, trip.currency);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move this booking?'),
        content: Text(
          'You\'ll travel ${_when(trip)} with ${trip.operatorName} and get '
          'a new seat. Your booking reference stays the same. '
          '${quote.refund > 0 ? '$money goes back to your original payment method.' : 'The fare is the same, so nothing is charged or refunded.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep current'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Move booking'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.confirm();
  }
}

String _when(TripSummary trip) =>
    '${Formatters.shortDate(trip.departure)}, ${Formatters.time(trip.departure)}';

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final ChangeDateState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChangeDateCubit>();
    switch (state.status) {
      case ChangeDateStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ChangeDateStatus.failed:
        return _Message(
          text: state.message ?? 'We couldn\'t load other departures.',
          onRetry: cubit.load,
        );
      case ChangeDateStatus.ready ||
          ChangeDateStatus.changing ||
          ChangeDateStatus.changed:
        if (state.trips.isEmpty) {
          return _Message(
            text:
                'There are no other departures on this route right now. '
                'Check again later, or cancel for a refund.',
            onRetry: cubit.load,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          itemCount: state.trips.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i == 0) {
              return const Text(
                'Prices include the service fee. Paying a difference isn\'t '
                'available yet, so dearer departures can\'t be picked.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              );
            }
            final trip = state.trips[i - 1];
            final quote = cubit.quoteFor(trip);
            return _DepartureTile(
              trip: trip,
              quote: quote,
              selected: trip == state.selected,
              onTap:
                  state.status == ChangeDateStatus.ready && cubit.canPick(trip)
                  ? () => cubit.select(trip)
                  : null,
            );
          },
        );
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// One departure: when, who, price and what moving there means for you.
class _DepartureTile extends StatelessWidget {
  const _DepartureTile({
    required this.trip,
    required this.quote,
    required this.selected,
    required this.onTap,
  });

  final TripSummary trip;
  final DateChangeQuote? quote;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _difference();
    final enabled = onTap != null || selected;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: selected ? AppColors.limeSoft : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.ink : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _when(trip),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trip.operatorName} · arrives '
                        '${Formatters.shortDate(trip.arrival)}, '
                        '${Formatters.time(trip.arrival)}',
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.money(trip.total, trip.currency),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color) _difference() {
    final q = quote;
    if (q == null) return ('No longer available', AppColors.muted);
    if (q.needsTopUp) {
      return (
        '+${Formatters.money(q.difference, trip.currency)} · not yet',
        AppColors.muted,
      );
    }
    if (q.refund > 0) {
      return (
        '${Formatters.money(q.refund, trip.currency)} back',
        AppColors.success,
      );
    }
    return ('Same price', AppColors.muted);
  }
}
