import 'package:bookme_summative_project/features/escrow/data/escrow_repository_impl.dart';
import 'package:bookme_summative_project/features/escrow/domain/escrow_record.dart';
import 'package:bookme_summative_project/features/trust/domain/refund_policy.dart';
import 'package:flutter_test/flutter_test.dart';

final held = InMemoryEscrowRepository.demoRecords.first;

EscrowRecord withStage(EscrowStage stage, {bool confirmed = true}) =>
    EscrowRecord(
      bookingId: held.bookingId,
      reference: held.reference,
      operatorName: held.operatorName,
      seatNumber: held.seatNumber,
      amount: held.amount,
      currency: held.currency,
      paymentMethodLabel: held.paymentMethodLabel,
      stage: stage,
      tripConfirmed: confirmed,
    );

List<EscrowStepState> statesOf(EscrowRecord r) => [
  for (final s in r.steps) s.state,
];

void main() {
  test('in escrow and confirmed: matches the Figma timeline', () {
    expect(held.amountLabel, '18,500 RWF');
    expect(held.statusLabel, 'CURRENT STATUS · IN ESCROW');
    expect(
      held.steps.first.description,
      '18,500 RWF received via MTN MoMo. Held securely by BookMe.',
    );
    expect(statesOf(held), [
      EscrowStepState.done,
      EscrowStepState.current,
      EscrowStepState.upcoming,
    ]);
  });

  test('paid but not confirmed yet: payment is the current step', () {
    final r = withStage(EscrowStage.held, confirmed: false);
    expect(statesOf(r), [
      EscrowStepState.current,
      EscrowStepState.upcoming,
      EscrowStepState.upcoming,
    ]);
  });

  test('released after boarding: boarding is the current step', () {
    final r = withStage(EscrowStage.released);
    expect(r.statusLabel, 'CURRENT STATUS · RELEASED');
    expect(r.protectedAmountLabel, 'Paid to operator');
    expect(statesOf(r).last, EscrowStepState.current);
  });

  test('refunded: two steps ending with the refund', () {
    final r = withStage(EscrowStage.refunded);
    expect(r.steps, hasLength(2));
    expect(r.steps.last.title, 'Refund Sent');
    expect(r.protectedAmountLabel, 'Refunded amount');
  });

  test('unknown escrow status from Firestore is treated as held', () {
    expect(EscrowStage.fromName(null), EscrowStage.held);
    expect(EscrowStage.fromName('something'), EscrowStage.held);
    expect(EscrowStage.fromName('refunded'), EscrowStage.refunded);
  });

  group('RefundPolicy', () {
    test('operator cancellation always qualifies', () {
      expect(
        RefundPolicy.qualifiesForRefund(
          operatorCancelled: true,
          delay: Duration.zero,
        ),
        isTrue,
      );
    });

    test('delays qualify only when longer than 2 hours', () {
      bool delayed(Duration d) =>
          RefundPolicy.qualifiesForRefund(operatorCancelled: false, delay: d);

      expect(delayed(const Duration(hours: 2)), isFalse);
      expect(delayed(const Duration(hours: 2, minutes: 20)), isTrue);
    });
  });
}
