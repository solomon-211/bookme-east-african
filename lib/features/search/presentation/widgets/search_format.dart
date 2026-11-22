import 'package:flutter/material.dart';

import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';

/// Display helpers used only by the Search screens. General ones (money,
/// time, date) live in `core/utils/formatters.dart`.
class SearchFormat {
  const SearchFormat._();

  /// Short price for the date strip: `15500` → `15.5k`, `120000` → `120k`,
  /// `1250000` → `1.3M`.
  static String compact(int amount) {
    if (amount >= 1000000) return '${_trim(amount / 1000000)}M';
    if (amount >= 1000) return '${_trim(amount / 1000)}k';
    return '$amount';
  }

  static String _trim(double value) {
    final text = value >= 100
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  /// `7 seats left`, `1 seat left`, `Fully booked`.
  static String seatsLeft(BusTrip trip) {
    if (trip.isFull) return 'Fully booked';
    final n = trip.seatsAvailable;
    return '$n seat${n == 1 ? '' : 's'} left';
  }

  static IconData amenityIcon(Amenity amenity) => switch (amenity) {
    Amenity.wifi => Icons.wifi,
    Amenity.ac => Icons.ac_unit,
    Amenity.recliningSeats => Icons.airline_seat_recline_extra,
    Amenity.usbCharging => Icons.usb,
    Amenity.toilet => Icons.wc,
  };

  /// `Executive · Wi-Fi · AC`: class plus the two amenities people ask
  /// about most.
  static String classLine(BusTrip trip) {
    final parts = [trip.serviceClass];
    if (trip.hasAmenity(Amenity.wifi)) parts.add('Wi-Fi');
    if (trip.hasAmenity(Amenity.ac)) parts.add('AC');
    return parts.join(' · ');
  }
}
