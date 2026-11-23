# bookme-east-african
Front-end &amp; Backend Implementation4

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
