import 'package:equatable/equatable.dart';

/// A city BookMe sells departures from or to, with its main bus park.
class City extends Equatable {
  const City({
    required this.name,
    required this.code,
    required this.station,
    required this.country,
    required this.currency,
  });

  /// e.g. `Kigali`. This exact string is stored in `trips.origin` /
  /// `trips.destination`, so search queries match on it.
  final String name;

  /// Short code shown in large type on tickets, e.g. `KGL`.
  final String code;

  /// Main boarding point, e.g. `Nyabugogo`.
  final String station;
  final String country;

  /// Fares for departures from this city are sold in this currency.
  final String currency;

  /// `Kigali · Nyabugogo`, as shown in the From / To fields.
  String get label => '$name · $station';

  @override
  List<Object?> get props => [name, code, station, country, currency];
}

/// Cities served by the seed data.
class Cities {
  const Cities._();

  static const kigali = City(
    name: 'Kigali',
    code: 'KGL',
    station: 'Nyabugogo',
    country: 'Rwanda',
    currency: 'RWF',
  );
  static const kampala = City(
    name: 'Kampala',
    code: 'KLA',
    station: 'Namirembe',
    country: 'Uganda',
    currency: 'UGX',
  );
  static const nairobi = City(
    name: 'Nairobi',
    code: 'NBO',
    station: 'Machakos',
    country: 'Kenya',
    currency: 'KES',
  );
  static const juba = City(
    name: 'Juba',
    code: 'JUB',
    station: 'Konyo Konyo',
    country: 'South Sudan',
    currency: 'SSP',
  );
  static const bujumbura = City(
    name: 'Bujumbura',
    code: 'BJM',
    station: 'Gare du Nord',
    country: 'Burundi',
    currency: 'BIF',
  );

  static const all = [kigali, kampala, nairobi, juba, bujumbura];

  /// Looks a city up by name, ignoring case. `null` when unknown.
  static City? byName(String name) {
    final key = name.trim().toLowerCase();
    for (final city in all) {
      if (city.name.toLowerCase() == key) return city;
    }
    return null;
  }
}
