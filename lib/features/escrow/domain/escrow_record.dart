import 'package:equatable/equatable.dart';

import '../../../core/utils/formatters.dart';

// Matches the `escrowStatus` field Booking & Payment writes on `payments`.
enum EscrowStage {
  held,
  released,
  refunded;

  static EscrowStage fromName(String? name) => switch (name) {
    'released' => EscrowStage.released,
    'refunded' => EscrowStage.refunded,
    _ => EscrowStage.held,
  };
}

enum EscrowStepState { done, current, upcoming }

enum StepIcon { check, boarding, refund }

class EscrowStep extends Equatable {
  const EscrowStep({
    required this.title,
    required this.description,
    required this.state,
    this.icon = StepIcon.check,
  });

  final String title;
  final String description;
  final EscrowStepState state;
  final StepIcon icon;

  @override
  List<Object?> get props => [title, description, state, icon];
}

// Everything the "Where your money is" screen needs about one booking.
class EscrowRecord extends Equatable {
  const EscrowRecord({
    required this.bookingId,
    required this.reference,
    required this.operatorName,
    required this.seatNumber,
    required this.amount,
    required this.currency,
    required this.paymentMethodLabel,
    required this.stage,
    required this.tripConfirmed,
  });

  final String bookingId;
  final String reference; // e.g. BME-7K2Q-4C
  final String operatorName;
  final String seatNumber;
  final int amount;
  final String currency;
  final String paymentMethodLabel; // e.g. MTN MoMo
  final EscrowStage stage;

  // True once the booking is paid and the seat is guaranteed.
  final bool tripConfirmed;

  String get amountLabel => Formatters.money(amount, currency);

  String get statusLabel => switch (stage) {
    EscrowStage.held => 'CURRENT STATUS · IN ESCROW',
    EscrowStage.released => 'CURRENT STATUS · RELEASED',
    EscrowStage.refunded => 'CURRENT STATUS · REFUNDED',
  };

  String get statusMessage => switch (stage) {
    EscrowStage.held =>
      'Your money is still with BookMe. No funds have been released to '
          'the operator.',
    EscrowStage.released =>
      'Your boarding was verified, so the fare was paid to $operatorName.',
    EscrowStage.refunded =>
      'Your money was sent back to your $paymentMethodLabel. Nothing was '
          'paid to the operator.',
  };

  String get protectedAmountLabel => switch (stage) {
    EscrowStage.held => 'Protected amount',
    EscrowStage.released => 'Paid to operator',
    EscrowStage.refunded => 'Refunded amount',
  };

  // The timeline. The most recent finished step is "current" (lime);
  // older ones are "done" (green); the rest are grey.
  List<EscrowStep> get steps {
    final payment = EscrowStep(
      title: 'Payment Received (In Escrow)',
      description:
          '$amountLabel received via $paymentMethodLabel. Held securely by '
          'BookMe.',
      state: EscrowStepState.done,
    );

    if (stage == EscrowStage.refunded) {
      return [
        payment,
        EscrowStep(
          title: 'Refund Sent',
          description:
              'The full $amountLabel went back to your $paymentMethodLabel. '
              'Processing time depends on your provider.',
          state: EscrowStepState.current,
          icon: StepIcon.refund,
        ),
      ];
    }

    final boarded = stage == EscrowStage.released;

    final steps = [
      payment,
      EscrowStep(
        title: 'Trip Confirmed',
        description: tripConfirmed
            ? '$operatorName · Seat $seatNumber is guaranteed. You\'re '
                  'protected until boarding.'
            : 'Waiting for $operatorName to confirm your seat.',
        state: tripConfirmed ? EscrowStepState.done : EscrowStepState.upcoming,
      ),
      EscrowStep(
        title: 'Boarding Verified',
        description: boarded
            ? 'Boarding verified. Funds released to $operatorName.'
            : 'Funds Released to Operator ONLY after successful, verified '
                  'boarding.',
        state: boarded ? EscrowStepState.done : EscrowStepState.upcoming,
        icon: StepIcon.boarding,
      ),
    ];

    // Promote the last finished step to "current".
    final lastDone = steps.lastIndexWhere(
      (s) => s.state == EscrowStepState.done,
    );
    final step = steps[lastDone];
    steps[lastDone] = EscrowStep(
      title: step.title,
      description: step.description,
      state: EscrowStepState.current,
      icon: step.icon,
    );
    return steps;
  }

  @override
  List<Object?> get props => [
    bookingId,
    reference,
    operatorName,
    seatNumber,
    amount,
    currency,
    paymentMethodLabel,
    stage,
    tripConfirmed,
  ];
}
