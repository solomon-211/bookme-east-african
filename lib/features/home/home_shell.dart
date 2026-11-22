import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../account/presentation/account_screen.dart';
import '../alerts/presentation/alerts_screen.dart';
import '../auth/bloc/auth_bloc.dart';
import '../escrow/presentation/escrow_screen.dart';
import '../search/presentation/search_navigation.dart';
import '../search/presentation/search_screen.dart';
import '../tickets/presentation/tickets_navigation.dart';
import '../tickets/presentation/tickets_screen.dart';
import 'home_tab_cubit.dart';

// The signed-in app: Search, My Trips, Alerts and Account.
// This is the one place the features are wired to each other.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeTabCubit(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  static void _openEscrow(BuildContext context, String bookingId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EscrowScreen(bookingId: bookingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = context.read<HomeTabCubit>();
    final palette = AppPalette.of(context);

    final tickets = TicketsNavigation(
      onFindBus: (_) => tabs.open(HomeTab.search),
      onOpenEscrowInfo: (ctx, ticket) => _openEscrow(ctx, ticket.id),
    );

    final screens = [
      SearchScreen(
        navigation: SearchNavigation(
          onViewTicket: tickets.openAfterPayment,
          onOpenAlerts: (ctx) {
            Navigator.of(ctx).popUntil((route) => route.isFirst);
            tabs.open(HomeTab.alerts);
          },
        ),
      ),
      TicketsScreen(navigation: tickets),
      AlertsScreen(onOpenSearch: () => tabs.open(HomeTab.search)),
      AccountScreen(
        onSignOut: () => context.read<AuthBloc>().add(const SignOutRequested()),
      ),
    ];

    return BlocBuilder<HomeTabCubit, HomeTab>(
      builder: (context, tab) {
        return Scaffold(
          body: IndexedStack(index: tab.index, children: screens),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: NavigationBar(
              selectedIndex: tab.index,
              onDestinationSelected: (i) => tabs.open(HomeTab.values[i]),
              backgroundColor: palette.card,
              indicatorColor: AppColors.lime,
              surfaceTintColor: Colors.transparent,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.search, color: AppColors.ink),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.work_outline),
                  selectedIcon: Icon(Icons.work_outline, color: AppColors.ink),
                  label: 'My Trips',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_none),
                  selectedIcon: Icon(
                    Icons.notifications_none,
                    color: AppColors.ink,
                  ),
                  label: 'Alerts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.ink,
                  ),
                  label: 'Account',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
