# BookMe East Africa

**Your seat, confirmed before you leave home.**

BookMe East Africa is a Flutter mobile app for booking cross-border bus
trips between Rwanda, Uganda, Kenya, Tanzania, South Sudan and Burundi.
Travellers search verified operators, hold a seat for ten minutes, pay with
mobile money, and board with a QR ticket that also works offline. Their
money stays in escrow until they board, and they get live alerts about
delays, cancellations and seats opening up.

The app is built with **Flutter**, **BLoC** for state management and
**Firebase** (Authentication and Cloud Firestore). It targets **Android and
iOS only**.

---

## Contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Database design](#database-design)
- [Security rules](#security-rules)
- [Getting started](#getting-started)
- [Loading the bus data](#loading-the-bus-data)
- [Testing](#testing)
- [Known limitations](#known-limitations)
- [Team](#team)

---

## Features

### Sign-in (Foundations & Auth)
- Welcome screen with three ways in: phone number with SMS code, email and
  password, or Google.
- Registration, login and password reset by email.
- The user stays signed in between launches; signing out returns to Welcome.

### Search
- Search trips by origin, destination and date, starting from the saved
  default departure city.
- Results with a date strip showing the lowest fare per day, plus filters
  (departure time, price range, operator, amenities) to narrow them.
- Trip details: stations, stops, border crossing, amenities, seats left.
- **Waitlist** for full trips: "Notify me" when a seat opens.

### Booking & Payment
- **Ten-minute seat hold** taken in a Firestore transaction, so two people
  can never hold the same seat.
- "Who's travelling?" form, with or without a saved passenger.
- Mock payment (MTN MoMo, M-Pesa, Airtel Money, Visa/Mastercard) with an
  "approve on your phone" step.
- **Someone else is paying:** send a 30-minute payment request by link or
  SMS.

### Tickets & Trips
- **My Trips** with upcoming and past trips, and a border checklist.
- Digital ticket with a **QR code**, saved on the phone so it works
  **offline**.
- Manage a booking: **change date** (same price or cheaper) or **cancel**
  with an automatic refund.

### Trust & Account
- **Escrow tracker:** a timeline showing the money is held by BookMe and only
  released to the operator after boarding.
- **Alerts** in real time: delays, cancellations, seats opening, price drops,
  payments protected and refunds. Mark as read, delete, filter by type.
- **Account:** profile update and verification status.
- **Saved passengers** with full create, read, update and delete.
- **Trust Center:** verified operators and their ratings.
- **Refund policy** in plain language.
- **Three saved preferences:** language, light/dark theme and default
  departure city. They survive closing and reopening the app.

---

## Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter 3.50 (Dart 3.12), Material 3 |
| State management | `flutter_bloc` (Bloc and Cubit), `equatable` |
| Backend | Firebase Authentication, Cloud Firestore |
| Navigation | `go_router` for sign-in routes; an `IndexedStack` bottom-tab shell after sign-in |
| Local storage | `shared_preferences` (preferences, offline tickets) |
| Other | `google_sign_in`, `qr_flutter`, `url_launcher` |
| Testing | `flutter_test`, `bloc_test`, `mocktail`, `integration_test` |

---

## Architecture

Each feature follows **clean architecture** with three layers:

```
presentation  ->  Widgets + Bloc/Cubit (UI state only)
domain        ->  Entities + abstract repository interfaces (pure Dart)
data          ->  Firestore / SharedPreferences implementations
```

- **Widgets never call Firebase directly.** A screen sends an event to its
  Bloc or Cubit, which calls a repository and emits a new state that the
  screen rebuilds from.
- Every repository has a **Firestore implementation** and an **in-memory
  implementation**. The app uses Firestore; the tests use the in-memory ones,
  so they run fast and without a network.
- Each feature exposes its repositories through one function, such as
  `trustAccountRepositoryProviders(prefs: prefs)`. `main.dart` provides them
  all with a single `MultiRepositoryProvider`.
- Features don't import each other's screens. They connect through small
  navigation objects (`SearchNavigation`, `TicketsNavigation`), which
  `HomeShell` wires together.
- **Settings load before the first frame,** so the app opens in the saved
  theme and language without flashing.

---

## Project structure

```
lib/
  main.dart             Firebase init, settings, every feature's repositories
  app.dart              MaterialApp.router, light/dark theme, status bar style
  firebase_options.dart Firebase config (Android and iOS)
  core/
    constants/          Supported countries and dial codes
    router/             go_router routes for sign-in and the home shell
    theme/              Colours, light/dark palette, ThemeData
    utils/              Validators and formatters
    widgets/            Shared buttons, fields, logo
  features/
    auth/               AuthBloc, sign-in screens
    home/               Bottom-tab shell (Search, My Trips, Alerts, Account)
    search/             SearchBloc, waitlist, results, trip details, seed data
    booking/            Seat hold, passenger form, payment flow
    tickets/            My Trips, QR ticket, offline cache, change/cancel
    escrow/             Escrow tracker
    alerts/             Real-time alerts
    account/            Profile, saved passengers
    trust/              Trust Center, refund policy
    settings/           Language, theme, default city (SharedPreferences)
test/                   Unit, bloc and widget tests (in-memory repositories)
integration_test/       Tickets flow against the Firebase emulators
tool/                   Seed export and upload scripts
firestore.rules         Security rules for every collection
firestore.indexes.json  Composite indexes
docs/                   Database architecture, security rules write-up
```

---

## Database design

Cloud Firestore, with these collections:

| Collection | What it holds |
|---|---|
| `users/{uid}` | Profile: name, email, phone, preferred payment |
| `users/{uid}/passengers` | Saved passengers (name, phone, ID number, nationality) |
| `users/{uid}/alerts` | The user's alerts (`kind`, `title`, `body`, `read`, `createdAt`) |
| `operators` | Bus companies, ratings, verification, refund policy |
| `routes` | Operator routes between two cities |
| `trips` | Scheduled departures with times, price and seats left |
| `trips/{id}/seats` | One document per seat: `available`, `held` or `booked` |
| `bookings` | A user's booking: trip, seat, passenger, amount, status |
| `payments` | Payment result and escrow status (`none` → `held`) |
| `waitlist/{userId_tripId}` | "Notify me" entries for full trips |

Composite indexes (in `firestore.indexes.json`):
- `trips`: `origin`, `destination`, `departureTime`
- `waitlist`: `userId`, `createdAt` descending
- `seats`: `status`, `holdExpiresAt`

See [docs/search/database_architecture.md](docs/search/database_architecture.md)
for the full schema.

---

## Security rules

[firestore.rules](firestore.rules) protects every collection:

1. **Signed in only:** nothing can be read without a Firebase Auth session.
2. **Owner only:** users touch only their own documents, by path
   (`users/{uid}/...`) or by a `userId` field.
3. **Reference data is read-only:** operators, routes and trips are seeded
   by an admin, not written by the app.
4. **Money is locked:** prices can't change after booking, a refund can't
   exceed what was paid, and the app can never mark escrow as released or
   refunded.
5. **Shape checks:** writes must use known fields with valid types and
   lengths, e.g. a passenger phone must be `+` followed by 12 digits.
6. **Closed by default:** anything not listed is denied.

Seat holds can only take a free or expired seat, last at most 30 minutes,
and be released or confirmed by the person holding them.

Full explanation: [docs/report/security_rules_and_limitations.md](docs/report/security_rules_and_limitations.md).

Deploy the rules and indexes with:

```sh
firebase deploy --only firestore:rules,firestore:indexes
```

---

## Getting started

### Prerequisites

- Flutter 3.47 or newer (stable channel) and Dart 3.12+
- Android Studio with an Android emulator, or a physical Android phone
  (Xcode for iOS)
- Java 17+ (Android Studio's bundled JDK works)
- Optional: Firebase CLI (`npm install -g firebase-tools`) and FlutterFire
  CLI (`dart pub global activate flutterfire_cli`)

### 1. Clone and install

```sh
git clone https://github.com/solomon-211/bookme-east-african.git
cd bookme-east-african
flutter pub get
```

### 2. Firebase

The repository is already connected to the Firebase project
**`bookme-east-africa`** (`lib/firebase_options.dart`,
`android/app/google-services.json`), so the app builds and runs as it is.

- **Google sign-in on your machine:** add your debug SHA-1 in the Firebase
  console (Project settings → Your apps → Android). Get it with:
  ```sh
  cd android && ./gradlew signingReport
  ```
  Ask the project owner to add you to the Firebase project if you don't
  have access.
- **Using your own Firebase project instead:** create a project, enable
  Email/Password, Google and Phone sign-in and a Firestore database, then
  run:
  ```sh
  flutterfire configure --platforms=android,ios
  firebase deploy --only firestore:rules,firestore:indexes
  ```
  and load the bus data (below).

### 3. Run

```sh
flutter devices          # find your emulator or phone
flutter run
```

Build an installable APK:

```sh
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

> **Mobile only.** Web and desktop builds are not supported;
> `firebase_options.dart` throws on those platforms.

### Troubleshooting

| Problem | Fix |
|---|---|
| `Can't find service: package` when installing | The emulator hasn't finished booting or is stuck. Cold-boot it from Device Manager, then run again. |
| `A network error … has occurred` at sign-in | The emulator lost DNS. Start it with `emulator -avd Pixel_7 -dns-server 8.8.8.8,1.1.1.1`. |
| Search shows no buses | The trips haven't been loaded, or the seeded dates have passed. See [Loading the bus data](#loading-the-bus-data). |
| Gradle download timeouts | Retry; timeouts are already raised in `android/gradle.properties`. |
| Phone SMS code never arrives | Real SMS needs the Firebase Blaze plan. Add a test phone number under Authentication → Sign-in method → Phone. |

---

## Loading the bus data

The app can't write operators or trips (the rules forbid it), so they are
uploaded once with admin rights.

```sh
# 1. Generate trips from today for the next 21 days
dart run tool/export_search_seed.dart --days 21

# 2. Firebase console > Project settings > Service accounts >
#    Generate new private key. Save it OUTSIDE the repo; never commit it.

# 3. Upload
cd tool/seed
npm install firebase-admin
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node seed_search.js
```

This writes 5 operators, 11 routes and 252 trips with their seats (about
11,300 writes, under the free plan's 20,000 per day). Re-running is safe; it
overwrites the same documents. Delete the key in the console when you're
done.

---

## Testing

```sh
flutter test                 # 199 tests: unit, bloc and widget
flutter test --coverage      # writes coverage/lcov.info
flutter analyze              # no issues
```

What's covered:
- **Unit tests:** validators, formatters, repositories, and preferences
  surviving a restart (`test/features/settings/settings_test.dart`).
- **Bloc/Cubit tests** with `bloc_test` and `mocktail` for every feature.
- **Widget tests:** the full home shell over in-memory repositories,
  sign-in screens, and layout checks on a small phone, a large phone and
  landscape, in both light and dark mode (`test/layout_test.dart`).
- **Integration test:** the Tickets flow and the real security rules
  against the Firebase emulators. See
  [integration_test/README.md](integration_test/README.md).

---

## Known limitations

- **Payments are simulated.** The mobile-money gateway is a mock; no real
  money moves.
- **No server code.** Releasing escrow after boarding, refunds and system
  alerts would need Cloud Functions (paid Blaze plan). Boarding isn't
  scanned, so a ticket always reads "Not yet boarded".
- **Phone SMS sign-in** needs the Blaze plan for real numbers; test numbers
  work on the free plan.
- **Seed data runs out.** Trips cover 21 days from the day they were
  generated and must be reloaded after that.
- **Waitlist notifications** are stored, but no push notification is sent
  when a seat opens.
- **Android and iOS only.**

---

## Team

| # | Member | Area |
|---|---|---|
| 1 | Ikenna Onugha | Foundations & Auth: Firebase setup, router, theme, AuthBloc and sign-in screens |
| 2 | Cherish Yusuf | Search: SearchBloc, waitlist, results, filters, trip details, seed data, indexes, ERD |
| 3 | Andrew Thon Riem | Booking & Payment: seat hold, passenger form, mock payment flow |
| 4 | Byiringiro Saad | Tickets & Trips: QR and offline tickets, My Trips, change date and cancel, emulator tests |
| 5 | Solomon Thiong Garang Leek | Trust & Account: escrow, alerts, account, saved passengers, Trust Center, refund policy, preferences, security rules; integration |

Built for the Mobile Application Development summative project at the
African Leadership University, Kigali, Rwanda.
