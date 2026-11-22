import 'package:flutter_bloc/flutter_bloc.dart';

// The four bottom tabs, in the order the Figma shows them.
enum HomeTab { search, myTrips, alerts, account }

// Which tab is open. Kept in a cubit so any screen can switch tabs
// (e.g. "Find a bus" on an empty My Trips jumps to Search).
class HomeTabCubit extends Cubit<HomeTab> {
  HomeTabCubit() : super(HomeTab.search);

  void open(HomeTab tab) => emit(tab);
}
