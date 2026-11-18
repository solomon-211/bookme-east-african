import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';

/// Turns low-level Firebase errors into messages a traveller understands.
BookingFailure mapFirebaseError(Object error, {required String fallback}) {
  if (error is BookingFailure) return error;
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return const BookingFailure(
          'You don\'t have permission to do that. Please sign in again.',
        );
      case 'unavailable':
      case 'deadline-exceeded':
        return const BookingFailure(
          'You seem to be offline. Check your connection and try again.',
        );
      case 'not-found':
        return const BookingFailure(
          'We couldn\'t find this booking any more. Please start again.',
        );
    }
  }
  return BookingFailure(fallback);
}
