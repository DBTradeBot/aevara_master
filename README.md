# Aevara

Aevara is a personal health & wellness tracking app built with Flutter, designed to unify data from wearable devices (Fitbit, Garmin, Oura, Whoop, Apple Health, Google Fit, Strava, Polar) into a single daily "vitality" score, with coaching, insights, and community features layered on top.

> **Status:** UI and app architecture are built out end-to-end across ~14 feature modules, with Firebase (Auth, Firestore, Cloud Functions, App Check) wired in and a serverless backend for score computation. The client currently runs against mock/dev data by default — real wearable data sync is scaffolded (see `wearable api/` and `functions/vendor/`) but not fully connected to live provider accounts.

## Features

- **Vitality dashboard** — a daily composite score with confidence indicators, trend gauges, and drill-down detail sheets for sleep, HRV, resting heart rate, steps, mood, and stress
- **Wearable sync hub** — a "connect providers" flow supporting eight device ecosystems, with per-provider status and sync transparency
- **AI coaching prompts** — contextual greeting/insight bubbles surfaced on the home screen
- **Challenges & leaderboards** — user-facing competition and progress tracking
- **Community feed** — social layer for sharing progress
- **Experiments** — a structured way for users to test how specific habits affect their metrics
- **Onboarding, auth, profile, and settings** — full account lifecycle
- **Built-in dev tooling** — a debug layer (route logging observer, dev-only screens) for internal QA

## Tech stack

- **Client:** Flutter (Android, iOS, Web, Windows, macOS, Linux), Riverpod for state management, `google_fonts`, `lottie` for animation
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, App Check, Storage, Analytics), Node.js/TypeScript Cloud Functions for vitality score computation, provider OAuth (Fitbit), and data export
- **Architecture:** feature-first folder structure (`lib/features/<feature>`) with shared `state/` (Riverpod providers), `data/` (models, services, Firestore contracts), and `core/` (env config, guards, telemetry) layers

## Project structure

```
lib/
  app.dart, main.dart       # entry point + root widget
  routing/                  # named routes, route guards
  shell/                    # app shell, nav observer
  features/                 # one folder per feature (home, auth, onboarding,
                             #   challenges, leaderboards, community, insights,
                             #   sync, data_hub, settings, profile, about, debug)
  state/                    # Riverpod providers per domain
  data/                     # services, models, Firestore contracts
  core/                     # env, guards, navigation, telemetry
  theme/, widgets/, charts/ # design system + reusable components
functions/                  # Firebase Cloud Functions (score computation,
                             #   provider sync, exports, leaderboards)
docs/                       # architecture reference
```

See `docs/AEVARA_STRUCTURE.md` for the canonical structure map.

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) and a Firebase project.

```bash
flutter pub get

# Run with FlutterFire config for your own Firebase project
flutterfire configure

flutter run -d chrome   # or -d <device_id> for mobile/desktop
```

Cloud Functions (optional, for full backend functionality):

```bash
cd functions
npm install
firebase deploy --only functions
```

## Screenshots

_Coming soon._

## License

MIT
