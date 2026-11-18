import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/booking_repository.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/payment_repository.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/passenger_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/payment_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/seat_hold_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/pages/payment_received_page.dart';
import 'package:bookme_summative_project/features/booking/presentation/pages/whos_travelling_page.dart';

/// Everything the booking screens need from the screen that opened them.
class BookingFlowArgs {
  const BookingFlowArgs({
    required this.trip,
    required this.onViewTicket,
    this.initialPhone = '',
  });

  final TripSummary trip;

  /// Opens the Digital Ticket screen (owned by Tickets & Trips).
  final void Function(BuildContext context, Booking booking) onViewTicket;

  /// The signed-in user's phone, used to pre-fill the forms.
  final String initialPhone;
}

/// Entry point and navigation helpers for the Booking & Payment screens.
///
/// The three cubits are created once when the flow starts and handed to
/// every screen with `BlocProvider.value`, so all screens share one
/// countdown and one payment.
class BookingFlow {
  const BookingFlow._();

  static const String entryRouteName = '/booking';

  /// Call from Trip Details → "Continue to Payment".
  static Future<void> start(
    BuildContext context, {
    required TripSummary trip,
    required void Function(BuildContext context, Booking booking) onViewTicket,
    String initialPhone = '',
  }) {
    final args = BookingFlowArgs(
      trip: trip,
      onViewTicket: onViewTicket,
      initialPhone: initialPhone,
    );
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: entryRouteName),
        builder: (_) => MultiBlocProvider(
          providers: [
            RepositoryProvider<BookingFlowArgs>.value(value: args),
            // lazy: false so the seat hold and the saved payment
            // preferences start loading as soon as the flow opens.
            BlocProvider<SeatHoldCubit>(
              lazy: false,
              create: (ctx) =>
                  SeatHoldCubit(repository: ctx.read<BookingRepository>())
                    ..start(trip),
            ),
            BlocProvider<PassengerCubit>(
              create: (ctx) =>
                  PassengerCubit(repository: ctx.read<BookingRepository>()),
            ),
            BlocProvider<PaymentCubit>(
              lazy: false,
              create: (ctx) =>
                  PaymentCubit(repository: ctx.read<PaymentRepository>())
                    ..loadPreferences(fallbackPhone: initialPhone),
            ),
          ],
          child: const WhosTravellingPage(),
        ),
      ),
    );
  }

  /// Pushes the next screen of the flow, sharing the same cubits.
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(_shared(context, page));
  }

  /// Swaps the current screen, e.g. when toggling "Someone else is paying".
  static Future<T?> replace<T>(BuildContext context, Widget page) {
    return Navigator.of(context)
        .pushReplacement<T, Object?>(_shared(context, page));
  }

  /// Payment done: removes every booking screen from the back stack and
  /// shows the receipt, so "back" can never return to a paid checkout.
  static void finish(
    BuildContext context, {
    required Booking booking,
    required Payment payment,
  }) {
    final args = context.read<BookingFlowArgs>();
    final navigator = Navigator.of(context)
      ..popUntil((route) => route.settings.name == entryRouteName);
    navigator.pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            PaymentReceivedPage(args: args, booking: booking, payment: payment),
      ),
    );
  }

  /// Leaves the flow completely (hold expired or bus full).
  static void exit(BuildContext context) {
    final navigator = Navigator.of(context)
      ..popUntil((route) => route.settings.name == entryRouteName);
    navigator.pop();
  }

  static MaterialPageRoute<T> _shared<T>(BuildContext context, Widget page) {
    final args = context.read<BookingFlowArgs>();
    final hold = context.read<SeatHoldCubit>();
    final passenger = context.read<PassengerCubit>();
    final payment = context.read<PaymentCubit>();
    return MaterialPageRoute<T>(
      builder: (_) => MultiBlocProvider(
        providers: [
          RepositoryProvider<BookingFlowArgs>.value(value: args),
          BlocProvider<SeatHoldCubit>.value(value: hold),
          BlocProvider<PassengerCubit>.value(value: passenger),
          BlocProvider<PaymentCubit>.value(value: payment),
        ],
        child: page,
      ),
    );
  }
}
