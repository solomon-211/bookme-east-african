import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

/// Countries for the city codes BookMe operators serve.
const Map<String, String> _countryByCityCode = {
  'KGL': 'Rwanda',
  'GOM': 'DR Congo',
  'KLA': 'Uganda',
  'NBO': 'Kenya',
  'ARK': 'Tanzania',
  'DAR': 'Tanzania',
  'JUB': 'South Sudan',
  'BJM': 'Burundi',
};

const Map<String, String> _cityByCode = {
  'KGL': 'Kigali',
  'GOM': 'Goma',
  'KLA': 'Kampala',
  'NBO': 'Nairobi',
  'ARK': 'Arusha',
  'DAR': 'Dar es Salaam',
  'JUB': 'Juba',
  'BJM': 'Bujumbura',
};

/// `KLA` → `Kampala`; unknown codes fall back to [station].
String cityName(String code, {required String station}) =>
    _cityByCode[code] ?? station;

/// The country a trip ends in, or `null` when the city is not known.
String? destinationCountry(Ticket ticket) =>
    _countryByCityCode[ticket.trip.toCode];

/// The country the traveller crosses into, or `null` for a domestic trip
/// (or one whose cities are not known), where no border checklist is shown.
String? borderCountry(Ticket ticket) {
  final from = _countryByCityCode[ticket.trip.fromCode];
  final to = destinationCountry(ticket);
  if (from == null || to == null || from == to) return null;
  return to;
}

/// One line of the "Before you cross" checklist.
class BorderCheck {
  const BorderCheck(this.label, {required this.done});

  final String label;
  final bool done;
}

/// What the traveller has already done and what is left before the border.
/// Ticks come from real booking data, never from hard-coded values.
List<BorderCheck> borderChecklist(Ticket ticket) {
  final idNumber = ticket.booking.passenger?.idNumber.trim() ?? '';
  return [
    BorderCheck('Seat paid. Nothing to pay at counter.', done: ticket.isPaid),
    BorderCheck('ID added to the border manifest', done: idNumber.isNotEmpty),
    const BorderCheck(
      'Check passport, health & visa requirements',
      done: false,
    ),
  ];
}
