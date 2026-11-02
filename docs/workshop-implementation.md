# Workshop implementation notes

This project has been updated against Workshops 3, 4, and 5. The workshop requirements describe a learning exercise; this document maps those requirements to the implementation and records the steps that need a real Supabase project or device.

## Workshop 3: Provider and scalable state

- `QueueProvider` owns queue state and actions and extends `ChangeNotifier`.
- `WaitingRoomScreen` reads the state with Provider and supports add, remove, and **Next Client** actions.
- `test/queue_provider_test.dart` checks local queue behavior; `test/waiting_room_widget_test.dart` covers the queue UI.

## Workshop 4: Supabase and real-time updates

- Supabase setup is optional at launch. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` through the `--dart-define` options in the README; without them, local queue features still work.
- The provider loads the Supabase `clients` stream, uploads pending local changes, processes queued deletes, and retries pending work every 15 seconds.
- The project has no Supabase URL/key and no remote project was provisioned as part of this code change. A live two-device sync demonstration therefore still requires the setup below.

### Supabase setup

Create a Supabase project and a `public.clients` table. Run this in the SQL editor (or create an equivalent table in Table Editor):

```sql
create table if not exists public.clients (
  id uuid primary key,
  name text not null,
  created_at timestamptz not null,
  lat double precision,
  lng double precision
);

alter table public.clients enable row level security;

create policy "Public queue can read clients"
  on public.clients for select to anon, authenticated using (true);
create policy "Public queue can add clients"
  on public.clients for insert to anon, authenticated with check (true);
create policy "Public queue can update clients"
  on public.clients for update to anon, authenticated using (true) with check (true);
create policy "Public queue can remove clients"
  on public.clients for delete to anon, authenticated using (true);
```

Enable anonymous sign-ins in Supabase Authentication if you want the app to sign in each device anonymously. Enable `clients` in the Supabase Realtime publication (Database → Publications → `supabase_realtime`). Then run with the project URL and anon/publishable key as shown in the README. The policies above intentionally implement the workshop's shared public queue: anyone with the app can read, add, change, or remove every row. Replace them with authenticated, per-user or per-room policies before using real customer data.

### Manual realtime demonstration

Run the configured app on two devices, emulators, or browser tabs. Add a name on device A and confirm it appears on device B without a refresh. Use **Next Client** on device B and confirm that the same row disappears on A. Also check the Supabase table. This step cannot be verified until project credentials are configured.

## Workshop 5: Offline queue and geolocation

- Queue entries are written to SQLite before any cloud request. The local queue remains usable if Supabase is missing or unreachable.
- A small local outbox tracks new entries and removals. Retrying a sync safely upserts new rows and then applies queued removals.
- An incoming full Supabase snapshot is merged with local pending work and reflects queue changes made on another device.
- Location is requested when adding an entry and stored as nullable latitude/longitude. Permission denial or unavailable location leaves the entry usable and displays “Location not captured.”
- Android and iOS location permission declarations are in the platform projects.
- The SQLite service has an in-memory mode for tests. Web uses a temporary in-memory fallback because this project uses `sqflite`, which does not provide browser persistence.

### Offline demonstration

On Android or iOS, launch with Supabase configured, add an entry while online, then turn off network access and add two more entries. They should appear immediately and remain after restarting the app. Restore the connection and allow the retry to run; confirm the entries reach Supabase and show on the second device. Add/remove entries with location permission both granted and denied.

## Verification status

The automated suite covers local storage-backed queue behavior and the UI's add/next flow. Cloud row-level security, realtime delivery across two devices, offline reconnection against a real Supabase project, and physical location permission prompts require the manual setup/demo above.
