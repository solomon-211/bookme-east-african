import 'package:flutter_test/flutter_test.dart';

import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/trip_filter.dart';

BusTrip _trip(
  String id, {
  int hour = 21,
  int minute = 0,
  int price = 18000,
  int serviceFee = 500,
  String operatorId = 'trinity',
  int seats = 10,
  String status = TripStatus.scheduled,
  Set<Amenity> amenities = const {Amenity.wifi, Amenity.ac},
}) {
  final departure = DateTime(2026, 10, 2, hour, minute);
  return BusTrip(
    id: id,
    routeId: 'r',
    operatorId: operatorId,
    operatorName: operatorId,
    origin: 'Kigali',
    fromCode: 'KGL',
    fromStation: 'Nyabugogo',
    destination: 'Kampala',
    toCode: 'KLA',
    toStation: 'Namirembe',
    departure: departure,
    arrival: departure.add(const Duration(hours: 9, minutes: 30)),
    price: price,
    serviceFee: serviceFee,
    currency: 'RWF',
    seatsTotal: 44,
    seatsAvailable: seats,
    status: status,
    amenities: amenities,
  );
}

List<String> _ids(List<BusTrip> trips) => [for (final t in trips) t.id];

void main() {
  group('DepartureWindow', () {
    test('morning is 06:00 up to 11:59', () {
      expect(DepartureWindow.morning.contains(DateTime(2026, 1, 1, 6)), isTrue);
      expect(DepartureWindow.morning.contains(DateTime(2026, 1, 1, 11, 59)), isTrue);
      expect(DepartureWindow.morning.contains(DateTime(2026, 1, 1, 12)), isFalse);
      expect(DepartureWindow.morning.contains(DateTime(2026, 1, 1, 5, 59)), isFalse);
    });

    test('afternoon is 12:00 up to 17:59', () {
      expect(DepartureWindow.afternoon.contains(DateTime(2026, 1, 1, 12)), isTrue);
      expect(DepartureWindow.afternoon.contains(DateTime(2026, 1, 1, 17, 59)), isTrue);
      expect(DepartureWindow.afternoon.contains(DateTime(2026, 1, 1, 18)), isFalse);
    });

    test('night wraps past midnight: 18:00 to 05:59', () {
      expect(DepartureWindow.night.contains(DateTime(2026, 1, 1, 18)), isTrue);
      expect(DepartureWindow.night.contains(DateTime(2026, 1, 1, 23, 59)), isTrue);
      expect(DepartureWindow.night.contains(DateTime(2026, 1, 1, 0)), isTrue);
      expect(DepartureWindow.night.contains(DateTime(2026, 1, 1, 5, 59)), isTrue);
      expect(DepartureWindow.night.contains(DateTime(2026, 1, 1, 6)), isFalse);
      expect(DepartureWindow.night.contains(DateTime(2026, 1, 1, 17, 59)), isFalse);
    });

    test('any matches every hour', () {
      for (var h = 0; h < 24; h++) {
        expect(DepartureWindow.any.contains(DateTime(2026, 1, 1, h)), isTrue);
      }
    });
  });

  group('TripFilter.matches', () {
    test('no filter matches everything', () {
      expect(TripFilter.none.matches(_trip('a')), isTrue);
      expect(TripFilter.none.isActive, isFalse);
      expect(TripFilter.none.activeCount, 0);
    });

    test('filters by departure window', () {
      const night = TripFilter(window: DepartureWindow.night);
      expect(night.matches(_trip('a', hour: 21)), isTrue);
      expect(night.matches(_trip('b', hour: 7)), isFalse);
    });

    test('price bounds are inclusive and use the total with fees', () {
      // total = 18,000 + 500 = 18,500
      final trip = _trip('a');
      expect(const TripFilter(maxPrice: 18500).matches(trip), isTrue);
      expect(const TripFilter(maxPrice: 18499).matches(trip), isFalse);
      expect(const TripFilter(minPrice: 18500).matches(trip), isTrue);
      expect(const TripFilter(minPrice: 18501).matches(trip), isFalse);
    });

    test('empty operator set means every operator', () {
      expect(const TripFilter().matches(_trip('a', operatorId: 'jaguar')), isTrue);
      const onlyTrinity = TripFilter(operatorIds: {'trinity'});
      expect(onlyTrinity.matches(_trip('a', operatorId: 'trinity')), isTrue);
      expect(onlyTrinity.matches(_trip('b', operatorId: 'jaguar')), isFalse);
    });

    test('a bus must have every chosen amenity', () {
      const wantsWifiAndUsb = TripFilter(
        amenities: {Amenity.wifi, Amenity.usbCharging},
      );
      expect(wantsWifiAndUsb.matches(_trip('a')), isFalse);
      expect(
        wantsWifiAndUsb.matches(
          _trip('b', amenities: {Amenity.wifi, Amenity.usbCharging, Amenity.ac}),
        ),
        isTrue,
      );
    });

    test('all filter groups combine with AND', () {
      const filter = TripFilter(
        window: DepartureWindow.night,
        maxPrice: 20000,
        operatorIds: {'trinity'},
        amenities: {Amenity.wifi},
      );
      expect(filter.activeCount, 4);
      expect(filter.matches(_trip('ok')), isTrue);
      expect(filter.matches(_trip('morning', hour: 8)), isFalse);
      expect(filter.matches(_trip('dear', price: 30000)), isFalse);
      expect(filter.matches(_trip('other', operatorId: 'ritco')), isFalse);
      expect(filter.matches(_trip('nowifi', amenities: {Amenity.ac})), isFalse);
    });
  });

  group('TripFilter.apply', () {
    final now = DateTime(2026, 10, 2, 12);

    test('drops cancelled trips and buses that already left', () {
      final trips = [
        _trip('left', hour: 9),
        _trip('cancelled', hour: 20, status: TripStatus.cancelled),
        _trip('ok', hour: 22),
      ];
      expect(_ids(TripFilter.none.apply(trips, now: now)), ['ok']);
    });

    test('sorts by departure with fully booked buses last', () {
      final trips = [
        _trip('full-early', hour: 13, seats: 0),
        _trip('late', hour: 22),
        _trip('early', hour: 19),
      ];
      expect(
        _ids(TripFilter.none.apply(trips, now: now)),
        ['early', 'late', 'full-early'],
      );
    });

    test('applies the filter to full buses too', () {
      final trips = [
        _trip('full-night', hour: 20, seats: 0),
        _trip('full-day', hour: 14, seats: 0),
      ];
      const night = TripFilter(window: DepartureWindow.night);
      expect(_ids(night.apply(trips, now: now)), ['full-night']);
    });

    test('does not change the input list', () {
      final trips = [_trip('b', hour: 22), _trip('a', hour: 19)];
      TripFilter.none.apply(trips, now: now);
      expect(_ids(trips), ['b', 'a']);
    });
  });

  group('TripFilter helpers', () {
    test('toggleAmenity adds then removes', () {
      final on = TripFilter.none.toggleAmenity(Amenity.wifi);
      expect(on.amenities, {Amenity.wifi});
      expect(on.toggleAmenity(Amenity.wifi).amenities, isEmpty);
    });

    test('copyWith clearPrice removes both bounds only', () {
      const filter = TripFilter(
        window: DepartureWindow.morning,
        minPrice: 1,
        maxPrice: 2,
      );
      final cleared = filter.copyWith(clearPrice: true);
      expect(cleared.minPrice, isNull);
      expect(cleared.maxPrice, isNull);
      expect(cleared.window, DepartureWindow.morning);
    });

    test('PriceRange.of finds lowest and highest totals', () {
      expect(PriceRange.of(const []), isNull);
      final range = PriceRange.of([
        _trip('a', price: 15000),
        _trip('b', price: 25000),
        _trip('c', price: 18000),
      ]);
      expect(range, const PriceRange(15500, 25500));
    });
  });
}
