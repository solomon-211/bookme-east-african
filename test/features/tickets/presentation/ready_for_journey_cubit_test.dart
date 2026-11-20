import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/journey_checklist_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/ready_for_journey_cubit.dart';

import '../../../helpers/test_ticket.dart';

void main() {
  late SharedPreferences prefs;
  late TicketCacheDataSource cache;
  late ReadyForJourneyCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cache = TicketCacheDataSource(prefs);
    cubit = ReadyForJourneyCubit(
      tickets: TicketsRepositoryImpl(
        source: InMemoryTicketsDataSource(),
        cache: cache,
        currentUserId: () => 'demo-user',
      ),
      checklist: JourneyChecklistRepositoryImpl(prefs),
      ticket: testTicket(),
    );
  });

  tearDown(() => cubit.close());

  test('reports whether the QR is saved on the phone', () async {
    cubit.load();
    expect(cubit.state.savedOffline, isFalse);

    await cache.save('demo-user', [testTicket()]);
    cubit.load();
    expect(cubit.state.savedOffline, isTrue);
  });

  test('ticks are saved per booking and survive a reload', () async {
    cubit.load();
    await cubit.toggle('passport');
    await cubit.toggle('visa');
    await cubit.toggle('visa');

    expect(cubit.state.checked, {'passport'});

    final again = ReadyForJourneyCubit(
      tickets: TicketsRepositoryImpl(
        source: InMemoryTicketsDataSource(),
        cache: cache,
        currentUserId: () => 'demo-user',
      ),
      checklist: JourneyChecklistRepositoryImpl(prefs),
      ticket: testTicket(),
    )..load();
    expect(again.state.checked, {'passport'});
    await again.close();
  });
}
