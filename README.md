# Waiting Room

A Flutter waiting-room queue that works locally without a connection and can sync with Supabase when configured. It uses Provider for app state, SQLite for device storage, and optional device location for queue entries.

## Run locally

```powershell
flutter pub get
flutter run
```

Without Supabase settings, the app runs as a device-local queue. On Android and iOS, entries persist in SQLite across app restarts. Location is optional; denying permission does not prevent someone joining the queue. Web uses an in-memory fallback for this workshop build.

## Connect Supabase

Follow the SQL, dashboard setup, and two-device demonstration steps in [docs/workshop-implementation.md](docs/workshop-implementation.md). Start the app with your project URL and anon key:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

The anon key is intended for client apps; protect the data with Row Level Security policies. Do not put a Supabase service-role key in a Flutter app.

## Verify

```powershell
flutter test
flutter analyze
```

Implementation status for Workshops 3, 4, and 5 is recorded in [docs/workshop-implementation.md](docs/workshop-implementation.md).
