import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/page_header.dart';
import '../../escrow/presentation/escrow_screen.dart';
import '../domain/alerts_repository.dart';
import '../domain/app_alert.dart';
import 'alert_card.dart';
import 'alerts_cubit.dart';
import 'alerts_state.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({this.onOpenSearch, this.clock, super.key});

  // "View available seat" and "See buses" belong to Search, which lives
  // in another tab. The shell passes a callback that switches to it.
  final VoidCallback? onOpenSearch;

  // Lets tests freeze time so "12m ago" doesn't drift.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AlertsCubit(context.read<AlertsRepository>())..start(),
      child: _AlertsView(
        onOpenSearch: onOpenSearch,
        now: clock ?? DateTime.now,
      ),
    );
  }
}

class _AlertsView extends StatelessWidget {
  const _AlertsView({required this.now, this.onOpenSearch});

  final VoidCallback? onOpenSearch;
  final DateTime Function() now;

  void _openAction(BuildContext context, AppAlert alert) {
    context.read<AlertsCubit>().markRead(alert);

    if (alert.bookingId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EscrowScreen(bookingId: alert.bookingId!),
        ),
      );
    } else {
      onOpenSearch?.call();
    }
  }

  void _delete(BuildContext context, AppAlert alert) {
    final cubit = context.read<AlertsCubit>()..delete(alert);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Alert removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.restore(alert),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AlertsCubit, AlertsState>(
          listenWhen: (a, b) =>
              b.errorMessage != null && a.errorMessage != b.errorMessage,
          listener: (context, state) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!))),
          builder: (context, state) {
            final visible = state.visibleAlerts;
            final time = now();

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: LargePageTitle(
                    title: 'Alerts',
                    subtitle: 'Travel updates you can trust',
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        for (final filter in AlertFilter.values) ...[
                          ChoicePill(
                            key: Key('filter_${filter.name}'),
                            label: filter.label,
                            selected: state.filter == filter,
                            onTap: () =>
                                context.read<AlertsCubit>().setFilter(filter),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'LATEST UPDATES',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ),
                if (state.status == AlertsStatus.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyAlerts(filter: state.filter),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final alert = visible[i];
                        return Dismissible(
                          key: ValueKey(alert.id),
                          direction: DismissDirection.endToStart,
                          background: const _DeleteBackground(),
                          onDismissed: (_) => _delete(context, alert),
                          child: AlertCard(
                            alert: alert,
                            timeLabel: alertTimeLabel(alert.createdAt, time),
                            onTap: () =>
                                context.read<AlertsCubit>().markRead(alert),
                            onAction: () => _openAction(context, alert),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts({required this.filter});

  final AlertFilter filter;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final what = filter == AlertFilter.all
        ? 'alerts'
        : filter.label.toLowerCase();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 40, color: palette.muted),
          const SizedBox(height: 12),
          Text(
            'No $what yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Delays, refunds and seat openings will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted),
          ),
        ],
      ),
    );
  }
}
