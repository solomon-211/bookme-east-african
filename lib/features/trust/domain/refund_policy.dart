// Wording of the refund policy. Kept in one place so the Trust Center,
// the Refund policy screen and the escrow screen never disagree.
class RefundPolicy {
  const RefundPolicy._();

  // Delays longer than this trigger an automatic full refund.
  static const delayThreshold = Duration(hours: 2);

  static const headline =
      '100% refund for operator cancellations or delays >2 hours';

  static const summary =
      'If your operator cancels the trip or departure is delayed more than '
      '2 hours, BookMe automatically triggers a full refund of your paid '
      'total, including the service fee.';

  static const sections = [
    PolicySection(
      'Where the refund goes',
      'Refunds return to the original mobile money number or card. Track '
          'the status in Alerts. Processing time depends on the payment '
          'provider.',
    ),
    PolicySection(
      'Changing or cancelling yourself',
      'Any fare difference or refund eligibility is shown before '
          'confirmation. Voluntary cancellation is subject to the fare '
          'policy; contact Help Center if unclear.',
    ),
    PolicySection(
      'When funds are released',
      'Your money stays in escrow and is released ONLY after successful, '
          'verified boarding — never merely because the scheduled '
          'departure time has arrived.',
    ),
  ];

  // Short version used in the escrow screen's protection box.
  static const shortProtection =
      '100% refund if the operator cancels or your bus is delayed more than '
      '2 hours. Refund updates appear in Alerts.';

  static bool qualifiesForRefund({
    required bool operatorCancelled,
    required Duration delay,
  }) {
    return operatorCancelled || delay > delayThreshold;
  }
}

class PolicySection {
  const PolicySection(this.title, this.body);

  final String title;
  final String body;
}
