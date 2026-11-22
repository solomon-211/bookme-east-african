# Firestore check (Tickets & Trips)

`tickets_firestore_test.dart` runs the real Firestore code for My Trips,
cancel, change date and remove from history against the Firebase
emulators, with the team's `firestore.rules` loaded. The unit tests use an
in-memory stand-in, so this is what checks the transactions, the
documents they write and the security rules together.

No real project or data is touched: the emulators run on this machine
under the demo project `demo-bookme`.

## Run it

1. Start the emulators from the folder with `firebase.json` and
   `firestore.rules` (Java must be installed):

   ```sh
   firebase emulators:start --project demo-bookme --only firestore,auth
   ```

2. Boot an iOS Simulator, then in another terminal, from the project root:

   ```sh
   flutter test integration_test/tickets_firestore_test.dart -d <simulator id>
   ```

   (`flutter devices` lists the id.) The simulator reaches the emulators on
   `127.0.0.1`. A macOS build doesn't work without extra setup: Firebase
   Auth on macOS needs keychain access, which needs the app signed with a
   registered development team.

Each test signs up a new user in the Auth emulator, seeds the trips, seats
and a paid booking as an admin (bypassing the rules, like the data Search
and Booking & Payment create), then acts as that user.

## Result (19 Nov 2026, iPhone 17 simulator, iOS 26.5)

All six tests pass with the team's `firestore.rules`. Change date and
"remove from history" originally failed with permission denied; the rules
now allow exactly:

* A paid booking moving to another departure at the same price or cheaper,
  adding one `changeHistory` entry, and taking a free seat whose
  `bookingId` points at that booking on that trip and seat.
* Deleting your own booking once it's cancelled or expired, or paid with
  the trip already arrived.
* A recorded `refundAmount` that is never more than the booking total.
