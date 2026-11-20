import 'package:flutter_bloc/flutter_bloc.dart';

enum TripsTab { upcoming, past }

/// Which tab of My Trips is selected. Kept apart from [MyTripsCubit] so a
/// live data update never resets the tab the traveller is looking at.
class TripsTabCubit extends Cubit<TripsTab> {
  TripsTabCubit() : super(TripsTab.upcoming);

  void select(TripsTab tab) => emit(tab);
}
