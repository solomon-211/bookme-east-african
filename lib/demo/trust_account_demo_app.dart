import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/bookme_themes.dart';
import '../core/widgets/page_header.dart';
import '../core/widgets/surface_card.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/alerts/presentation/alerts_screen.dart';
import '../features/escrow/presentation/escrow_screen.dart';
import '../features/settings/presentation/settings_cubit.dart';
import '../features/settings/presentation/settings_state.dart';

// Runs the Trust & Account screens on their own until they are plugged
// into the team's router and HomeShell. Search and My Trips are stand-ins.
class TrustAccountDemoApp extends StatelessWidget {
  const TrustAccountDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) => a.themeMode != b.themeMode,
      builder: (context, settings) => MaterialApp(
        title: 'BookMe',
        debugShowCheckedModeBanner: false,
        theme: BookMeThemes.light,
        darkTheme: BookMeThemes.dark,
        themeMode: settings.themeMode,
        home: const DemoShell(),
      ),
    );
  }
}

class DemoShell extends StatefulWidget {
  const DemoShell({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const _SearchStandIn(),
          const _TripsStandIn(),
          AlertsScreen(onOpenSearch: () => setState(() => _tab = 0)),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: palette.card,
          indicatorColor: AppColors.lime,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? palette.text
                  : palette.muted,
            ),
          ),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            const NavigationDestination(
              icon: Icon(Icons.work_outline),
              label: 'My Trips',
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_none),
              selectedIcon: Icon(
                Icons.notifications_none,
                color: isDark ? AppColors.ink : null,
              ),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(
                Icons.person_outline,
                color: isDark ? AppColors.ink : null,
              ),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

// Shows the saved departure city, so changing it on Account is visible.
class _SearchStandIn extends StatelessWidget {
  const _SearchStandIn();

  @override
  Widget build(BuildContext context) {
    final city = context.select(
      (SettingsCubit c) => c.state.settings.defaultDepartureCity,
    );
    final palette = AppPalette.of(context);

    return SafeArea(
      child: ListView(
        children: [
          const LargePageTitle(
            title: 'Where to next?',
            subtitle: 'Search is built by the Search teammate',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SurfaceCard(
              child: Row(
                children: [
                  Icon(Icons.place_outlined, color: palette.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FROM',
                          style: TextStyle(fontSize: 11, color: palette.muted),
                        ),
                        Text(
                          city,
                          key: const Key('search_from'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: palette.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripsStandIn extends StatelessWidget {
  const _TripsStandIn();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          const LargePageTitle(
            title: 'My Trips',
            subtitle: 'Built by the Tickets & Trips teammate',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SurfaceCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const EscrowScreen(bookingId: 'demo-booking-1'),
                ),
              ),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock_outline),
                title: Text('Where your money is'),
                subtitle: Text('BME-7K2Q-4C · Trinity Express'),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
