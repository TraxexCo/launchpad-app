# LaunchPad

LaunchPad is a mobile marketplace where student developers and local businesses
complete small software projects. Students discover nearby businesses, present
portfolio work, submit proposals, collaborate, deliver files or links, and
complete a classroom PayMongo payment flow. Businesses publish jobs, compare
students, fund contracts, review deliverables, request revisions, and approve
completion. A web-only administrator portal handles verification, reports,
disputes, accounts, job moderation, and payment monitoring.

## Roles and primary workflows

### Student mobile application

- Register, confirm email, sign in, recover a password, and restore a session.
- Browse and search open jobs, save jobs, and view nearby businesses on a map.
- Build a portfolio manually or from public GitHub repositories.
- Submit and withdraw proposals and track each decision.
- Use contract chat, submit versioned deliverables, respond to revisions, and
  review the business after completion.
- Upload a profile photo and private university verification document.

### Business mobile application

- Register and manage a business profile and map location.
- Create, read, update, and delete owned job posts.
- Review student proposals, portfolios, profile photos, and verification state.
- Accept one proposal atomically and automatically reject competing proposals.
- Fund the contract through PayMongo test mode, review deliverables, request a
  revision, approve completion, cancel eligible work, or open a dispute.
- Upload a profile photo and private business verification document.

### Administrator web portal

- Review private verification documents and approve or reject submissions.
- Resolve reports and contract disputes.
- Suspend or restore accounts and close or reopen job posts.
- Monitor classroom payment and refund states.

The hosted portal is available at
<https://launchpad-mobile-prince.web.app/admin/login>.

## Architecture

```text
Flutter Android app                 Flutter web admin
        |                                  |
        +----------- Supabase Auth --------+
        +------- Postgres and Realtime ----+
        +--------- Supabase Storage -------+
        +--------- Edge Functions ---------+
                       |
            PayMongo test API and FCM

Student portfolio ---------------- GitHub REST API
Nearby business map --------------- Mapbox or OpenStreetMap tiles
```

- **Presentation:** Flutter screens, shared widgets, GoRouter role guards, and
  the Campus Utility design system.
- **Application services:** authentication, jobs, proposals, contracts,
  payments, notifications, location, reports, verification, and moderation.
- **Backend:** Supabase Auth, PostgreSQL tables and protected RPC functions,
  Row Level Security, Realtime, Storage, Vault, database webhooks, and Edge
  Functions.
- **External APIs:** PayMongo checkout sessions in test mode, Firebase Cloud
  Messaging for Android, GitHub public repositories, and map tiles.

## Main data flow

1. Supabase Auth establishes the session. A profile lookup determines the role
   and rejects suspended accounts.
2. Students and businesses read or write through Row Level Security policies.
3. Sensitive multi-record transitions use PostgreSQL RPC functions. Proposal
   acceptance locks the job and creates the contract and conversation in one
   transaction.
4. Supabase Realtime streams messages, payments, and notification changes.
5. Protected files use private Storage buckets and short-lived signed URLs.
   Profile photos use a public bucket with owner-only write policies.
6. Edge Functions keep PayMongo and Firebase secrets off the mobile client.

## Local setup

Requirements:

- Flutter SDK compatible with Dart `3.12.2`
- Android SDK and an Android phone or emulator
- Access to the configured Supabase and Firebase projects

```powershell
flutter pub get
Copy-Item supabase.local.example.json supabase.local.json
# Fill in SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, and optionally MAPBOX_PUBLIC_TOKEN.
flutter run --dart-define-from-file=supabase.local.json
```

Never add the ignored `supabase.local.json`, service-role keys, PayMongo secret
keys, Firebase service-account credentials, database passwords, or signing keys
to Git.

The Android application ID is `com.prince.launchpad`. Mobile callbacks use
`launchpad://auth-callback` and `launchpad://payment-return`.

See [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for backend configuration and Edge
Functions. Apply migrations in `supabase/migrations` by filename order when
creating a new project.

## Verification commands

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=supabase.local.json
flutter build web --release --dart-define-from-file=supabase.local.json
```

The repository currently contains 81 Flutter unit and widget tests plus SQL
rollback suites under `supabase/tests`. Automated checks do not replace the
two-account physical-device run required before the final examination.

## Final demonstration sequence

1. Launch the installed Android build and sign in with prepared student and
   business accounts.
2. Create, edit, search for, and delete a disposable job to demonstrate CRUD.
3. Submit a proposal, accept it from the business account, and open the
   generated contract and chat.
4. Complete a PayMongo test checkout, start work, submit a deliverable, request
   a revision, resubmit, and approve completion.
5. Show realtime chat and Android push notification delivery.
6. Show nearby-business location results and the interactive map.
7. Upload a verification document and profile photo, then review the document
   in the administrator portal.
8. Demonstrate a validation error, an offline state, a role-blocked route, and
   one guarded delete confirmation.

## Known release limits

- iOS push delivery and iOS device testing are outside the current Android
  classroom demonstration.
- Android release signing still uses the debug key and is not Play Store ready.
- Physical-device email callbacks, PayMongo return, GPS, background push, and
  two-user realtime behavior must be recorded before they can be marked passed.
- The project is an academic demonstration and must remain in PayMongo test
  mode.
