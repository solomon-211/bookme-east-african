import 'escrow_record.dart';

abstract class EscrowRepository {
  // Emits null while there is no successful payment for the booking yet.
  Stream<EscrowRecord?> watchEscrow(String bookingId);
}
