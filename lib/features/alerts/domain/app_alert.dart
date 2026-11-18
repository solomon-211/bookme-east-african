import 'package:equatable/equatable.dart';

// What happened. Decides the icon, the colour and which filter chip
// the alert appears under.
enum AlertKind {
  delay,
  tripCancelled,
  seatOpened,
  priceWatch,
  paymentProtected,
  refundReceived;

  static AlertKind fromName(String? name) => AlertKind.values.firstWhere(
    (k) => k.name == name,
    orElse: () => AlertKind.paymentProtected,
  );

  AlertFilter get filter => switch (this) {
    AlertKind.delay || AlertKind.tripCancelled => AlertFilter.trips,
    AlertKind.seatOpened || AlertKind.priceWatch => AlertFilter.seatAlerts,
    AlertKind.paymentProtected ||
    AlertKind.refundReceived => AlertFilter.payments,
  };

  // Delays are the one thing that needs attention, so they stand out.
  bool get isUrgent => this == AlertKind.delay;
}

enum AlertFilter {
  all('All'),
  trips('Trips'),
  seatAlerts('Seat alerts'),
  payments('Payments');

  const AlertFilter(this.label);

  final String label;
}

class AppAlert extends Equatable {
  const AppAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.actionLabel,
    this.bookingId,
    this.read = false,
  });

  final String id;
  final AlertKind kind;
  final String title;
  final String body;
  final DateTime createdAt;

  // Green link at the bottom of the card, e.g. "Track automatic refund".
  final String? actionLabel;

  // Set for alerts that open the escrow screen.
  final String? bookingId;
  final bool read;

  bool matches(AlertFilter filter) =>
      filter == AlertFilter.all || kind.filter == filter;

  AppAlert copyWith({bool? read}) => AppAlert(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    actionLabel: actionLabel,
    bookingId: bookingId,
    read: read ?? this.read,
  );

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    body,
    createdAt,
    actionLabel,
    bookingId,
    read,
  ];
}

// "Now", "12m ago", "2h ago", "Earlier today", "Yesterday", "14 Sep".
String alertTimeLabel(DateTime createdAt, DateTime now) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final age = now.difference(createdAt);
  if (age.inMinutes < 1) return 'Now';
  if (age.inMinutes < 60) return '${age.inMinutes}m ago';
  if (age.inHours < 3) return '${age.inHours}h ago';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final daysAgo = today.difference(day).inDays;

  if (daysAgo == 0) return 'Earlier today';
  if (daysAgo == 1) return 'Yesterday';
  return '${createdAt.day} ${months[createdAt.month - 1]}';
}
