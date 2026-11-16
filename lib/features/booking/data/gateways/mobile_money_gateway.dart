import 'dart:async';

import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';

/// What the payment provider told us.
class GatewayResult {
  const GatewayResult.approved(String this.providerRef)
    : approved = true,
      reason = null;

  const GatewayResult.declined(String this.reason)
    : approved = false,
      providerRef = null;

  final bool approved;
  final String? providerRef;
  final String? reason;
}

/// Talks to MTN MoMo / M-Pesa / Airtel / card processors.
///
/// Only [MockMobileMoneyGateway] exists today. A real version would call
/// the provider's "request to pay" API from a Cloud Function and receive
/// the result through a webhook, never from the phone.
abstract class MobileMoneyGateway {
  Future<GatewayResult> requestToPay({
    required String paymentId,
    required PaymentMethod method,
    required String phone,
    required int amount,
    required String currency,
  });
}

/// Simulates a provider so the full flow can be demonstrated without real
/// money. Test numbers:
/// * ending in `0000` → the payer declines,
/// * anything else → approved after [approvalDelay].
class MockMobileMoneyGateway implements MobileMoneyGateway {
  MockMobileMoneyGateway({this.approvalDelay = const Duration(seconds: 6)});

  final Duration approvalDelay;

  static const String declineSuffix = '0000';

  @override
  Future<GatewayResult> requestToPay({
    required String paymentId,
    required PaymentMethod method,
    required String phone,
    required int amount,
    required String currency,
  }) async {
    await Future<void>.delayed(approvalDelay);

    if (method.needsPhone && phone.endsWith(declineSuffix)) {
      return const GatewayResult.declined(
        'The payment was declined on the phone. No money was taken.',
      );
    }
    final shortId = paymentId.length > 8
        ? paymentId.substring(0, 8)
        : paymentId;
    return GatewayResult.approved('MOCK-${method.name}-$shortId');
  }
}
