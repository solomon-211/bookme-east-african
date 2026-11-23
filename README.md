# BookMe East Africa

**Your seat, confirmed before you leave home.**

BookMe East Africa is a Flutter mobile app that lets travellers book cross-border bus trips across Rwanda, Uganda, Kenya, Tanzania, South Sudan and Burundi. You search verified operators, hold a seat for ten minutes, pay with mobile money, and board with a QR ticket that works even without internet. Your money stays in escrow until you actually board, and you get live alerts about delays, cancellations and seats opening up.

Built with **Flutter**, **BLoC** for state management and **Firebase** (Authentication and Cloud Firestore). Targets **Android and iOS only**.

| | |
|---|---|
| **Repository** | https://github.com/solomon-211/bookme-east-african |
| **Demo video** | _[add link here]_ |
| **Firebase project** | `bookme-east-africa` |

---

## Table of Contents

1. [Features](#features)
2. [Tech Stack](#tech-stack)
3. [Architecture](#architecture)
4. [Why BLoC](#why-bloc)
5. [Project Structure](#project-structure)
6. [Database Design](#database-design)
7. [Security Rules](#security-rules)
8. [Saved Preferences](#saved-preferences)
9. [Getting Started](#getting-started)
10. [Loading the Bus Data](#loading-the-bus-data)
11. [Testing and Code Quality](#testing-and-code-quality)
12. [Git Workflow](#git-workflow)
13. [Known Limitations](#known-limitations)
14. [Future Work](#future-work)
15. [Team](#team)

---

## Features

### Sign-in
- Welcome screen with three sign-in options: phone number with SMS code, email and password, or Google.
- Registration, login, logout and password reset all work out of the box.
- The user stays signed in between app launches — signing out brings them back to the Welcome screen.
- Every form validates input before anything is sent to the server.

### Search
- Search trips by origin, destination and date, starting from your saved default departure city.
- Results include a date strip showing the lowest fare per day, plus filters for departure time, price range, operator and amenities.
- Trip details show stations, stops, border crossings, amenities and seats remaining.
- **Waitlist** for full trips — tap "Notify me" and you'll be alerted when a seat opens up.

### Booking & Payment
- **Ten-minute seat hold** using a Firestore transaction, so two people can never hold the same seat at the same time.
- "Who's travelling?" form supports both new passengers and saved ones.
- Mock payment via MTN MoMo, M-Pesa, Airtel Money or Visa/Mastercard, with an "approve on your phone" step.
- **Someone else is paying?** Send them a 30-minute payment request by link or SMS.

### Tickets & Trips
- **My Trips** shows upcoming and past trips, with a border checklist for cross-border travel.
- Digital ticket with a **QR code**, saved locally so it works **offline**.
- Manage a booking: **change the date** (same price or cheaper) or **cancel** with an automatic refund.
- Remove old or cancelled trips from your history whenever you want.

### Trust & Account
- **Escrow tracker** — a timeline that shows your money is held by BookMe and only released to the operator after you board.
- **Real-time alerts** for delays, cancellations, seat openings, price drops, payment protection and refunds. Mark as read, delete or filter by type.
- **Account screen** for updating your profile and checking verification status.
- **Saved passengers** with full create, read, update and delete support.
- **Trust Center** showing verified operators and their ratings.
- **Refund policy** written in plain language, not legal jargon.
- **Three saved preferences** — language, light/dark theme and default departure city — all restored when you reopen the app.

### CRUD at a Glance

| Data | Create | Read | Update | Delete |
|---|:---:|:---:|:---:|:---:|
| User profile (`users`) | ✅ at sign-up | ✅ live | ✅ edit profile | — (admin only) |
| Saved passengers | ✅ | ✅ live | ✅ | ✅ |
| Alerts | ✅ | ✅ live | ✅ mark read | ✅ |
| Bookings | ✅ seat hold | ✅ My Trips | ✅ pay, change date, cancel | ✅ remove from history |
| Payments | ✅ | ✅ escrow tracker | ✅ payment result | — |
| Waitlist | ✅ notify me | ✅ | ✅ | ✅ leave |

---

## Tech Stack

| Area | Choice |
|---|---|
| Framework | Flutter 3.50 (Dart 3.12), Material 3 |
| State management | `flutter_bloc` (Bloc and Cubit), `equatable` |
| Backend | Firebase Authentication, Cloud Firestore |
| Navigation | `go_router` for sign-in routes; `IndexedStack` bottom-tab shell after sign-in |
| Local storage | `shared_preferences` (preferences and offline tickets) |
| Other packages | `google_sign_in`, `qr_flutter`, `url_launcher` |
| Testing | `flutter_test`, `bloc_test`, `mocktail`, `integration_test` |

---

## Architecture

Every feature follows **clean architecture** with three layers:

```
presentation  →  Widgets + Bloc/Cubit (UI state only)
domain        →  Entities + abstract repository interfaces (pure Dart)
data          →  Firestore / SharedPreferences implementations
```

A few things worth knowing about how this is wired together:

- **Widgets never call Firebase directly.** A screen sends an event to its Bloc or Cubit, which calls a repository and emits a new state. The screen rebuilds from that state.
- Every repository has a **Firestore implementation** and an **in-memory implementation**. The app uses Firestore; tests use the in-memory ones, so they run fast with no network needed.
- Each feature exposes its repositories through a single function like `trustAccountRepositoryProviders(prefs: prefs)`. `main.dart` wires them all together with one `MultiRepositoryProvider`.
- Features don't import each other's screens. They connect through small navigation objects (`SearchNavigation`, `TicketsNavigation`), which `HomeShell` wires together.
- **Settings load before the first frame**, so the app opens in the correct theme and language without any flash.

---

## Why BLoC

- **Separation of concerns.** UI code only draws a state and sends events. Business rules live in Blocs and Cubits. Firebase code lives in repositories. Each part can change without breaking the others.
- **Predictable state.** Every screen state is an immutable `Equatable` class, so the UI always reflects one known state — loading, loaded or error — and nothing changes behind the widget's back.
- **Real-time data fits naturally.** Firestore `snapshots()` streams feed straight into Cubits, which emit a new state on every change. That's how alerts, saved passengers and My Trips stay up to date live.
- **Easy to test.** With `bloc_test` we verify that an event produces exactly the expected sequence of states, using in-memory repositories and no network.
- **Bloc or Cubit, as needed.** Flows with many events (sign-in, search) use a full `Bloc`; simpler state (settings, selected tab, alerts) uses a lighter `Cubit`.

---

## Project Structure

```
lib/
  main.dart             Firebase init, settings, all feature repositories
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
docs/                   Database architecture, security rules
firestore.rules         Security rules for every collection
firestore.indexes.json  Composite indexes
```

Each feature folder follows the same three-layer structure:

```
features/account/
  domain/        user_profile.dart, saved_passenger.dart, account_repository.dart
  data/          account_repository_impl.dart (Firestore), in_memory_account_repository.dart
  presentation/  account_cubit.dart, account_state.dart, account_screen.dart, ...
```

---

## Database Design

Cloud Firestore is a document database, so related data is either nested under its owner (subcollections) or linked by an ID field:

| Collection | What it holds | Linked to |
|---|---|---|
| `users/{uid}` | Profile: name, email, phone, preferred payment | Firebase Auth user (same `uid`) |
| `users/{uid}/passengers` | Saved passengers: name, phone, ID number, nationality | Owner by path |
| `users/{uid}/alerts` | Alerts: `kind`, `title`, `body`, `read`, `createdAt` | Owner by path, optional `bookingId` |
| `operators` | Bus companies, ratings, verification, refund policy | — |
| `routes` | An operator's route between two cities | `operatorId` |
| `trips` | Scheduled departures with times, price and seats left | `routeId`, `operatorId` |
| `trips/{id}/seats` | One document per seat: `available`, `held` or `booked` | Trip by path, `heldBy`, `bookingId` |
| `bookings` | Trip, seat, passenger, amount, status, reference | `userId`, `tripId`, `paymentId` |
| `payments` | Payment result and escrow status (`none` → `held`) | `userId`, `bookingId` |
| `waitlist/{userId_tripId}` | "Notify me" entries for full trips | `userId`, `tripId` |

**Relationships:** a user has many passengers, alerts, bookings, payments and waitlist entries. An operator runs many routes, a route has many trips, and a trip has many seats. A booking belongs to one user, one trip and one seat, and has one payment.

**Composite indexes** (in `firestore.indexes.json`):
- `trips`: `origin`, `destination`, `departureTime` — used by the search query
- `waitlist`: `userId`, `createdAt` descending — a user's waitlist entries
- `seats`: `status`, `holdExpiresAt` — finding expired holds

More detail: [docs/search/database_architecture.md](docs/search/database_architecture.md).

---

## Security Rules

[firestore.rules](firestore.rules) protects every collection with six principles:

1. **Signed in only** — nothing can be read without a Firebase Auth session.
2. **Owner only** — users can only touch their own documents, by path (`users/{uid}/...`) or by a `userId` field.
3. **Reference data is read-only** — operators, routes and trips are seeded by an admin and can't be written by the app.
4. **Money is locked** — prices can't change after booking, a refund can't exceed what was paid, and the app can never mark escrow as released or refunded.
5. **Shape checks** — writes must use known fields with valid types and lengths. For example, a passenger phone must be `+` followed by 12 digits.
6. **Closed by default** — anything not explicitly listed is denied.

| Collection | Read | Write |
|---|---|---|
| `users/{uid}` and its `passengers`, `alerts` | Owner | Owner, with field checks (alerts: only `read` can change) |
| `operators`, `routes`, `trips` | Signed in | Never (admin seed only) |
| `trips/{id}/seats` | Signed in | Take a free seat, release or extend your own hold, confirm your own booking |
| `bookings` | Owner | Owner; price, trip and reference are locked after creation |
| `payments` | Owner | Owner; escrow can only move from `none` to `held` |
| `waitlist` | Owner | Owner; ID must be `userId_tripId` |

**Two layers of validation.** Forms check input in the app first (for example `AccountValidators.phone`), giving users instant feedback. The rules enforce the same checks on the server, so bad data is rejected even if someone bypasses the app entirely.

Full explanation: [docs/report/security_rules_and_limitations.md](docs/report/security_rules_and_limitations.md).

Deploy the rules and indexes with:

```sh
firebase deploy --only firestore:rules,firestore:indexes
```

---

## Saved Preferences

Three preferences are stored on the device with `SharedPreferences` and restored on every launch:

| Preference | Key | Options |
|---|---|---|
| Language | `settings.languageCode` | English, Français, Kiswahili, Kinyarwanda |
| Theme | `settings.themeMode` | Light, Dark, Same as phone |
| Default departure city | `settings.defaultDepartureCity` | Any supported city |

`SettingsCubit` saves each change immediately and emits a new state, so the whole app rebuilds at once. `main.dart` loads preferences **before the first frame**, so the app never flashes the wrong theme on startup. A unit test (`test/features/settings/settings_test.dart`) confirms all three survive an app restart.

---

## Getting Started

### Prerequisites

- Flutter 3.47 or newer (stable channel) and Dart 3.12+
- Android Studio with an Android emulator, or a physical Android or iOS device
- Java 17+ (Android Studio's bundled JDK works fine)
- Optional: Firebase CLI (`npm install -g firebase-tools`) and FlutterFire CLI (`dart pub global activate flutterfire_cli`)

Check your setup with:

```sh
flutter doctor
```

### 1. Clone and Install

```sh
git clone https://github.com/solomon-211/bookme-east-african.git
cd bookme-east-african
flutter pub get
```

### 2. Firebase

The repo is already connected to the Firebase project **`bookme-east-africa`** (`lib/firebase_options.dart`, `android/app/google-services.json`), so the app builds and runs as-is.

- **Google sign-in on your machine:** add your debug SHA-1 in the Firebase console (Project settings → Your apps → Android). Get it with:
  ```sh
  cd android && ./gradlew signingReport
  ```
  Ask the project owner to add you to the Firebase project if you don't have access yet.

- **Using your own Firebase project:**
  1. Create a project in the [Firebase console](https://console.firebase.google.com).
  2. Enable **Email/Password**, **Google** and **Phone** sign-in under Authentication.
  3. Create a **Firestore** database.
  4. Connect the app and deploy the rules:
     ```sh
     flutterfire configure --platforms=android,ios
     firebase deploy --only firestore:rules,firestore:indexes
     ```
  5. Load the bus data (see [Loading the Bus Data](#loading-the-bus-data)).

### 3. Run

```sh
flutter devices          # find your emulator or phone
flutter run
```

Build a release APK:

```sh
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> **Mobile only.** Web and desktop builds are not supported — `firebase_options.dart` will throw on those platforms.

### 4. Try It Out

1. Tap **Get Started** or **Continue with Google**, or sign in with email.
2. Search **Kigali → Kampala** for today or any date in the next three weeks.
3. Pick a bus and a seat, fill in who's travelling and pay with the mock mobile money.
4. Open **My Trips** to see your QR ticket, and **Alerts** for live updates.
5. In **Account**, add a saved passenger and switch to dark mode, then close and reopen the app to confirm your preferences were saved.

### Troubleshooting

| Problem | Fix |
|---|---|
| `Can't find service: package` when installing | The emulator hasn't finished booting. Cold-boot it from Device Manager, then try again. |
| `A network error has occurred` at sign-in | The emulator lost DNS. Start it with `emulator -avd Pixel_7 -dns-server 8.8.8.8,1.1.1.1`. |
| Search shows no buses | Trips haven't been loaded, or the seeded dates have passed. See [Loading the Bus Data](#loading-the-bus-data). |
| Google sign-in fails | Your machine's SHA-1 isn't registered in Firebase (see step 2). |
| Gradle download timeouts | Just retry — timeouts are already raised in `android/gradle.properties`. |
| Phone SMS code never arrives | Real SMS needs the Firebase Blaze plan. Add a test phone number under Authentication → Sign-in method → Phone. |

---

## Loading the Bus Data

The app can't write operators or trips (the security rules block it), so they're uploaded once using admin credentials.

```sh
# 1. Generate trips from today for the next 21 days
dart run tool/export_search_seed.dart --days 21

# 2. Firebase console → Project settings → Service accounts →
#    Generate new private key. Save it OUTSIDE the repo — never commit it.

# 3. Upload
cd tool/seed
npm install firebase-admin
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node seed_search.js
```

This writes 5 operators, 11 routes and 252 trips with their seats — about 11,300 writes, well under the free plan's 20,000 per day. Re-running is safe; it overwrites the same documents. Delete the service account key from the Firebase console when you're done.

---

## Testing and Code Quality

```sh
flutter test                 # 199 tests: unit, bloc and widget
flutter test --coverage      # writes coverage/lcov.info
flutter analyze              # no issues
dart format --set-exit-if-changed lib test
```

Here's what's covered:

| Kind | Examples |
|---|---|
| **Unit tests** | Validators, formatters, filter logic, repositories, preferences surviving a restart |
| **Bloc / Cubit tests** | Every feature's Bloc or Cubit with `bloc_test` and `mocktail`: sign-in, search, seat hold, payment, tickets, alerts, account, settings |
| **Widget tests** | Full home shell over in-memory repositories, login screen, adding a saved passenger, switching to dark mode |
| **Layout tests** | Every tab and sign-in screen on a small phone, large phone and landscape — in both light and dark mode, with no overflow |
| **Integration test** | The Tickets flow and real security rules against the Firebase emulators ([integration_test/README.md](integration_test/README.md)) |

---

## Git Workflow

- `main` always holds working, stable code.
- Each team member built their feature on a dedicated branch (e.g. `feature/cherish-search`, `andrewthonriem/booking-payment`, `saad`, `solomon/settings-preferences`) and merged it into `main` via a **pull request**.
- `integration/full-app` brought all features together, resolved merge conflicts, removed placeholder and duplicate code, and wired everything into one working app.
- Commit messages describe what changed, e.g. *"Add payment repository and seat hold cubit tests"*.
- Secrets never go in the repo — Firebase admin keys and build output are listed in `.gitignore`.

See each member's contributions with:

```sh
git shortlog -sn --no-merges
```

---

## Known Limitations

- **Payments are simulated.** The mobile-money gateway is a mock — no real money moves.
- **No server-side code.** Releasing escrow after boarding, processing refunds and sending system alerts would all need Cloud Functions (which require the paid Blaze plan). Since boarding isn't scanned, a ticket always shows "Not yet boarded".
- **Phone SMS sign-in** requires the Blaze plan for real numbers. Test numbers work fine on the free plan.
- **Seed data expires.** Trips cover 21 days from when they were generated and need to be reloaded after that.
- **Waitlist notifications** are stored in Firestore, but no push notification is sent when a seat actually opens.
- **Translations are incomplete.** The language preference is saved and restored, but the app's text is still English only.
- **Android and iOS only** — no web or desktop support.

---

## Future Work

- Real mobile-money integration with the MTN MoMo and M-Pesa APIs.
- Cloud Functions to release escrow when the conductor scans the QR code, issue refunds automatically and send alerts.
- Push notifications via Firebase Cloud Messaging for delays and waitlist seats.
- An operator-facing app for managing timetables and scanning tickets at boarding.
- Full translation into French, Kiswahili and Kinyarwanda.

---

## Team

| # | Member | Area |
|---|---|---|
| 1 | Ikenna Onugha | Foundations & Auth — Firebase setup, router, theme, AuthBloc and sign-in screens |
| 2 | Cherish Yusuf | Search — SearchBloc, waitlist, results, filters, trip details, seed data, indexes, ERD |
| 3 | Andrew Thon Riem | Booking & Payment — seat hold, passenger form, mock payment flow |
| 4 | Byiringiro Saad | Tickets & Trips — QR and offline tickets, My Trips, change date and cancel, emulator tests |
| 5 | Solomon Thiong Garang Leek | Trust & Account — escrow, alerts, account, saved passengers, Trust Center, refund policy, preferences, security rules and integration |

Built for the Mobile Application Development summative project at the African Leadership University, Kigali, Rwanda.
