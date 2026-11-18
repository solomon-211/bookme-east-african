# Security Rules and Known Limitations

*Report section: Trust & Account (Person 5)*

## 1. Firestore security rules

The rules live in `firestore.rules` at the project root and cover every collection the app uses. They follow five principles:

1. **Signed-in only.** No document can be read or written without a Firebase Auth session.
2. **Owner only.** A user can touch only documents tied to their own `uid`, either through the document path (`users/{uid}/...`) or a `userId` field.
3. **Reference data is read-only.** `operators` and `trips` are seeded from the Firebase console and cannot be changed from the app.
4. **Money can't be edited after the fact.** Prices, amounts and escrow outcomes are locked once written.
5. **Shape checks.** Writes must use known field names and sensible types and lengths, so bad data cannot be stored.

A final catch-all rule (`match /{document=**}`) denies everything not explicitly allowed. A collection added later is therefore closed by default rather than open.

### 1.1 Rules per collection

| Collection | Read | Create | Update | Delete | Why |
|---|---|---|---|---|---|
| `users/{uid}` | owner | owner, valid shape | owner, valid shape | never | Profile and travel documents are personal. Account deletion is an admin task. |
| `users/{uid}/passengers` | owner | owner, validated | owner, validated | owner | Full CRUD for saved passengers. The phone must be `+` and 12 digits. |
| `users/{uid}/alerts` | owner | owner, known `kind` | owner, **only `read`** | owner | The user can mark an alert read or delete it, but cannot rewrite what it says. |
| `operators` | signed in | never | never | never | Ratings come from verified feedback, not from the app. |
| `trips` | signed in | never | never | never | Timetable data is seeded. |
| `trips/{id}/seats` | signed in | never | holder only, see 1.2 | never | Prevents double-booking and seat hijacking. |
| `bookings` | owner | owner, status `held`, amount > 0 | owner; price, trip and reference locked | never | Cancelling is a status change, so a record stays for refunds. |
| `payments` | owner | owner, escrow `none` | owner; escrow can only become `held` | never | The client can never mark money as released or refunded. |
| `waitlist` | owner | owner | never | owner | Join or leave a waitlist. |

### 1.2 How the seat-hold rules stop abuse

A seat can be updated only in four ways. Each is checked against the seat's current state (`resource.data`):

- **Take a free seat.** Allowed only if the seat is `available` or its hold has already expired. The new hold must belong to the caller and last at most about 30 minutes.
- **Release your own hold.** Allowed only if `heldBy` is the caller.
- **Extend your own hold** (used for "someone else is paying"). Allowed only for the holder, and again for 30 minutes at most.
- **Confirm your own hold as `booked`** after payment.

Only the four hold fields (`status`, `heldBy`, `holdExpiresAt`, `bookingId`) may change. A user therefore cannot steal a seat someone else is holding, cannot hold a seat forever, and cannot edit the seat's other data.

### 1.3 Escrow protection

The escrow promise is that money is released to the operator **only after verified boarding**. The rules enforce this on the server side: a client update may move `payments.escrowStatus` only to `none` or `held`. The values `released` and `refunded` can be written only by the Admin SDK (a trusted server or Cloud Function), which bypasses the rules. Even a modified app cannot mark its own payment as refunded, or pay an operator early.

### 1.4 Alerts

Alerts sit in a subcollection under each user. Ownership comes from the path, so a missing `userId` field cannot leak data. On update, `affectedKeys().hasOnly(['read'])` means the only change a user can make is marking an alert read. They cannot, for example, edit a refund notice to show a different amount.

### 1.5 Testing the rules

The rules were written against the exact fields each feature writes, checked in the code:
- Auth's `users` document, including `uid`, `providers` and `lastLoginAt`.
- Booking & Payment's seat transaction, payment batch and `updatedAt` stamps.
- Account's profile and passenger forms.

**Recommended before submission:** run the Firebase Emulator Suite (`firebase emulators:start --only firestore`) and replay the booking flow. Then deploy with `firebase deploy --only firestore:rules`.

## 2. Known limitations

| Area | Limitation | Impact |
|---|---|---|
| Escrow release | No backend exists yet to verify boarding and set `escrowStatus` to `released` or `refunded`. In the demo these states come from sample data. | The full escrow lifecycle cannot happen live without a Cloud Function. |
| Payments | Mobile money is a mock gateway that runs inside the app, so the client records the payment result. | A modified client could mark an unpaid booking as `held`. A real provider callback should be handled server-side. |
| Language | The language choice (en/fr/sw/rw) is saved and restored, but the screens are not yet translated. | Selecting Français keeps English text. |
| Alerts | Alerts are stored in Firestore but no push notifications (FCM) are sent. The list loads the newest 50. | Users see alerts only when they open the app. Older alerts are not paged in. |
| Operator ratings | Ratings are read from the `operators` collection; there is no screen yet for passengers to submit feedback. | Ratings are static seed values. |
| Profile | One ID document and one mobile money number per user. | Users with both a passport and an EAC ID must choose one. |
| Validation | Phone validation accepts +250, +256, +254, +255, +211 and +257 numbers only. | Travellers from outside East Africa cannot save their own number. |
| Offline | Firestore's offline cache keeps the last data, but edits made offline are only confirmed when the user reconnects. | A user may see "saved" before the server has accepted the write. |
| Rules testing | The rules have not been run against the Firestore emulator with automated rules tests. | A mismatch with a teammate's write could appear only at runtime. |

## 3. Future work

1. **Cloud Functions for escrow.** Release funds when a boarding QR is scanned by the operator, and refund automatically when a trip is cancelled or delayed more than 2 hours. Each step writes an alert.
2. **Real payment callbacks.** Receive MTN MoMo, Airtel Money and M-Pesa callbacks on the server and remove `escrowStatus` writes from the client entirely.
3. **Push notifications (FCM)** for delays, refunds and waitlist seats, with per-type opt-outs on the Account screen.
4. **Full localisation.** Move all UI strings into ARB files with `flutter_localizations` so the saved language actually changes the app.
5. **Rules unit tests** with `@firebase/rules-unit-testing`, run in CI on every pull request.
6. **Passenger feedback and ratings.** After a completed trip, ask for a rating that feeds the operator's safety score.
7. **Multiple documents and wallets** per profile, with a default for checkout.
