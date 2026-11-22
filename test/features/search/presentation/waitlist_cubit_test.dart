import 'package:flutter_test/flutter_test.dart';

import 'package:bookme_summative_project/features/search/data/repositories/in_memory_search_repositories.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';
import 'package:bookme_summative_project/features/search/presentation/cubits/waitlist_cubit.dart';

void main() {
  final now = DateTime(2026, 10, 1, 8);
  late InMemoryWaitlistRepository repository;
  late WaitlistCubit cubit;
  late BusTrip fullTrip;

  setUp(() {
    repository = InMemoryWaitlistRepository(userId: 'u1', clock: () => now);
    cubit = WaitlistCubit(repository: repository)..start();
    fullTrip = InMemorySearchRepository.seedTrips(
      now,
      days: 1,
    ).firstWhere((t) => t.isFull);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('join creates one entry with a normalised phone', () async {
    final entry = await cubit.join(fullTrip, '+250 78 123 4412');
    expect(entry, isNotNull);
    expect(entry!.id, 'u1_${fullTrip.id}');
    expect(entry.phone, '+250781234412');
    expect(cubit.state.isOnWaitlist(fullTrip.id), isTrue);
    expect(repository.entries, hasLength(1));
  });

  test('joining twice does not create a second entry', () async {
    await cubit.join(fullTrip, '+250781234412');
    await cubit.join(fullTrip, '+250781234412');
    expect(repository.entries, hasLength(1));
  });

  test('an invalid phone is refused before any write', () async {
    final entry = await cubit.join(fullTrip, '0781');
    expect(entry, isNull);
    expect(cubit.state.errorMessage, isNotNull);
    expect(repository.entries, isEmpty);
  });

  test('leave deletes the entry', () async {
    await cubit.join(fullTrip, '+250781234412');
    expect(await cubit.leave(fullTrip.id), isTrue);
    expect(cubit.state.isOnWaitlist(fullTrip.id), isFalse);
    expect(repository.entries, isEmpty);
  });

  test('a failed join reports the message and clears the spinner', () async {
    repository.failure = const SearchFailure('offline');
    final entry = await cubit.join(fullTrip, '+250781234412');
    expect(entry, isNull);
    expect(cubit.state.errorMessage, 'offline');
    expect(cubit.state.busyTripId, isNull);
  });
}
