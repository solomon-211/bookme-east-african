# bookme-east-african
Front-end &amp; Backend Implementation4

# bookme_summative_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Search Module

The Search module lets a traveller find and compare bus trips.

### Features

- Home search for trips
- Results list
- Filters to narrow results
- Trip details screen
- Waitlist for trips that are full

### How it works

- **SearchBloc** manages search and filter state.
- **WaitlistCubit** manages waitlist state.
- Trip and operator data is stored in Cloud Firestore.
- Composite indexes are defined in `firestore.indexes.json`.

README and documentation: Cherish Yusuf