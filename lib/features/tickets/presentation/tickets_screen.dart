import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

// TODO(teammate): the user's tickets and QR boarding passes.
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(title: 'Tickets');
import 'package:bookme_summative_project/features/tickets/presentation/pages/my_trips_page.dart';
import 'package:bookme_summative_project/features/tickets/presentation/tickets_navigation.dart';

/// The Tickets tab of the home shell: My Trips, with every ticket screen
/// reachable from it.
///
/// Needs the providers from `ticketsRepositoryProviders` above
/// `MaterialApp`. Works as `const TicketsScreen()`; pass [navigation] to
/// connect "Find a bus" and "Escrow info" to the other tabs.
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({this.navigation = const TicketsNavigation(), super.key});

  final TicketsNavigation navigation;

  @override
  Widget build(BuildContext context) {
    return MyTripsPage(actions: navigation.myTripsActions);
  }
}
