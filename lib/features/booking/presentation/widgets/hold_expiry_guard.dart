import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/presentation/booking_flow.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/seat_hold_cubit.dart';

/// Wrap each booking screen in this. When the 10-minute hold runs out it
/// explains what happened and takes the traveller back out of the flow.
///
/// Only the screen on top reacts, so the dialog never appears twice.
class HoldExpiryGuard extends StatelessWidget {
  const HoldExpiryGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SeatHoldCubit, SeatHoldState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SeatHoldStatus.expired,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        final seat = state.booking?.seatNumber ?? '';
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            void backToTrip() {
              Navigator.of(dialogContext).pop();
              BookingFlow.exit(context);
            }

            // The system back button does the same as "Back to trip", so
            // the traveller is never left on a screen whose seat is gone.
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) backToTrip();
              },
              child: AlertDialog(
                title: const Text('Your seat hold ended'),
                content: Text(
                  'Seat $seat was released so other travellers can book it. '
                  'You have not been charged. Pick the trip again to get a '
                  'new 10-minute hold.',
                ),
                actions: [
                  TextButton(
                    onPressed: backToTrip,
                    child: const Text('Back to trip'),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: child,
    );
  }
}
