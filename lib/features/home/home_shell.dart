import 'package:flutter/material.dart';

import '../booking/presentation/booking_screen.dart';
import '../profile/presentation/account_screen.dart';
import '../search/presentation/search_screen.dart';
import '../tickets/presentation/tickets_screen.dart';

/// Bottom navigation: Search, Booking & Payment, Tickets, Account.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          SearchScreen(),
          BookingScreen(),
          TicketsScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.payments_outlined), label: 'Booking'),
          NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined), label: 'Tickets'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}
