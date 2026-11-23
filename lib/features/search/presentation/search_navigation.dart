import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/auth/bloc/auth_bloc.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/presentation/booking_flow.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/presentation/bloc/search_bloc.dart';
import 'package:bookme_summative_project/features/search/presentation/cubits/waitlist_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/tickets_navigation.dart';

/// Connects Search to the rest of the app. Other features only pass in
/// what they own; anything left out falls back to a sensible default.
///
/// * [onViewTicket]: "View My Digital Ticket" after payment (Tickets).
/// * [onOpenAlerts]: "Manage in Alerts" on the waitlist dialog (Alerts).
class SearchNavigation {
  const SearchNavigation({this.onViewTicket, this.onOpenAlerts});

  final void Function(BuildContext context, Booking booking)? onViewTicket;
  final void Function(BuildContext context)? onOpenAlerts;

  /// Trip Details → "Continue to Payment": hands over to Booking & Payment.
  Future<void> startBooking(BuildContext context, BusTrip trip) {
    return BookingFlow.start(
      context,
      trip: trip.toSummary(),
      onViewTicket: onViewTicket ?? const TicketsNavigation().openAfterPayment,
      initialPhone: currentPhone(context),
    );
  }

  void openAlerts(BuildContext context) {
    final open = onOpenAlerts;
    if (open != null) return open(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your seat alerts are listed on the bus in Search. '
          'We\'ll also text you when a seat opens.',
        ),
      ),
    );
  }

  /// The signed-in traveller's phone, or '' (e.g. signed in with email).
  static String currentPhone(BuildContext context) {
    try {
      return context.read<AuthBloc>().state.user?.phoneNumber ?? '';
    } on Object {
      // No AuthBloc above us (offline demo or a widget test).
      return '';
    }
  }

  /// The traveller's first name for the greeting, or `null`.
  static String? firstName(BuildContext context) {
    try {
      final name = context.read<AuthBloc>().state.user?.displayName?.trim();
      if (name == null || name.isEmpty) return null;
      return name.split(RegExp(r'\s+')).first;
    } on Object {
      return null;
    }
  }

  /// Pushes a Search screen that shares the tab's SearchBloc and
  /// WaitlistCubit (and this navigation).
  static Future<T?> push<T>(BuildContext context, Widget page) {
    final search = context.read<SearchBloc>();
    final waitlist = context.read<WaitlistCubit>();
    final navigation = context.read<SearchNavigation>();
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => MultiBlocProvider(
          providers: [
            RepositoryProvider<SearchNavigation>.value(value: navigation),
            BlocProvider<SearchBloc>.value(value: search),
            BlocProvider<WaitlistCubit>.value(value: waitlist),
          ],
          child: page,
        ),
      ),
    );
  }
}
