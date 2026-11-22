// Uploads the Search seed data to Firestore with the Admin SDK.
//
// The app may not write operators or trips (see firestore.rules), so seed
// data goes in with admin rights. Steps:
//
//   1. dart run tool/export_search_seed.dart
//   2. Firebase console > Project settings > Service accounts >
//      Generate new private key. Save it OUTSIDE the repo (never commit it).
//   3. cd tool/seed && npm install firebase-admin
//   4. GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node seed_search.js
//
// Re-running is safe: ids are predictable, so documents are overwritten.
// Seats are reset: free seats become 'available', the rest 'booked'.

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

admin.initializeApp({ credential: admin.credential.applicationDefault() });
const db = admin.firestore();
const { Timestamp } = admin.firestore;

const ISO = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/;

// ISO strings from the Dart export -> Firestore timestamps, recursively.
function withTimestamps(value) {
  if (typeof value === 'string' && ISO.test(value)) {
    return Timestamp.fromDate(new Date(value));
  }
  if (Array.isArray(value)) return value.map(withTimestamps);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, withTimestamps(v)]),
    );
  }
  return value;
}

// Firestore batches hold at most 500 writes.
async function writeAll(writes) {
  for (let i = 0; i < writes.length; i += 450) {
    const batch = db.batch();
    for (const [ref, data] of writes.slice(i, i + 450)) batch.set(ref, data);
    await batch.commit();
  }
}

async function main() {
  const file = path.join(__dirname, 'search_seed.json');
  const seed = JSON.parse(fs.readFileSync(file, 'utf8'));
  const writes = [];

  for (const { id, ...op } of seed.operators) {
    writes.push([db.collection('operators').doc(id), op]);
  }
  for (const { id, ...route } of seed.routes) {
    writes.push([db.collection('routes').doc(id), route]);
  }
  for (const { id, seatNumbers, ...trip } of seed.trips) {
    const ref = db.collection('trips').doc(id);
    writes.push([ref, withTimestamps(trip)]);
    seatNumbers.forEach((number, i) => {
      writes.push([
        ref.collection('seats').doc(number),
        { status: i < trip.seatsAvailable ? 'available' : 'booked' },
      ]);
    });
  }

  await writeAll(writes);
  console.log(
    `Seeded ${seed.operators.length} operators, ${seed.routes.length} ` +
      `routes, ${seed.trips.length} trips (${writes.length} writes).`,
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
