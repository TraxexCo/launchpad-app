# LaunchPad

LaunchPad is a mobile marketplace where student developers find nearby local
business projects, submit proposals, collaborate, deliver work, and complete a
classroom PayMongo payment flow. A web-only administrator portal handles
verification, reports, disputes, and payment monitoring.

## Main workflows

- Student and business registration with email confirmation and recovery links
- Nearby business discovery with device location and an interactive map
- Job posting, proposals, acceptance, chat, saved jobs, and reviews
- Contract lifecycle: funded, in progress, submitted, revision requested,
  completed, cancelled, and disputed
- Versioned file or link deliverables with participant-only storage access
- PayMongo test checkout, return link, status sync, and classroom release state
- Identity-document upload and an administrator review queue
- In-app realtime notifications with validated destinations
- Privacy, terms, crash diagnostics, and authenticated account deletion

## Run

```powershell
flutter pub get
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_KEY
```

The Android application ID is `com.prince.launchpad`. Custom links use
`launchpad://auth-callback` and `launchpad://payment-return`.

See [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for database and Edge Function setup.
The SQL migrations in `supabase/migrations` are the source of truth and must be
applied in filename order.
