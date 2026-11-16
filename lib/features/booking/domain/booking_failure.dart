/// A problem the traveller should see, already worded politely.
///
/// The data layer converts Firebase and gateway errors into this type so the
/// presentation layer never has to know about Firebase error codes.
class BookingFailure implements Exception {
  const BookingFailure(this.message);

  final String message;

  @override
  String toString() => 'BookingFailure: $message';
}
