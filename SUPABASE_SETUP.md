# LaunchPad Supabase setup

## What you need

The hosted `launchpad` project has already been created in the free **LaunchPad** organization, in Singapore. Supabase runs in the cloud; you do not need to install a database server, Docker, or the Supabase CLI to use this project. You do need Flutter and internet access when running the app.

Project dashboard: https://supabase.com/dashboard/project/oboyvpcziyjydyfguucs

## What has been applied

The SQL files through `202609220005_contract_lifecycle.sql` were run in this project's SQL Editor on 22 September 2026. They create the tables, row level security policies, signup triggers, proposal and job RPCs, contract snapshots, conversations, and realtime publications. Do not paste and run them again in this same project. Keep them as the repeatable schema for a **new** project; a future CLI setup will need to mark these existing changes as applied before using CLI migrations.

Two later migrations were applied in **SQL Editor** on 2 October 2026, in this order:

1. `202610010006_reports.sql` creates the protected reports table used by the Report action.
2. `202610010007_marketplace_lifecycle.sql` completes contract approval and two-sided reviews, adds project notifications, and corrects notification permissions.

Do not run either migration again in this project. The rollback verification script was run after migration 007 and returned `marketplace lifecycle assertions passed; test rows rolled back`.

Migrations 008, 009, and 010 were applied in **SQL Editor** by 11 October 2026.
They complete the skill catalog, nearby business and notification preferences,
protected payment records, and funded-contract lifecycle rules. Do not run them
again in this project.

Migrations 011, 012, and 013 were applied through the Supabase Management API
on 11 October 2026. Migration 014 activates Firebase push dispatch through a
protected database webhook. Migration 015 adds administrator job moderation.
Migration 016 creates the public profile-photo bucket with owner-only writes.
All migrations through `202610170016_profile_images.sql` are active in the
hosted project. Do not run them again in this project.

To inspect your data, open **Database → Tables**. To inspect user accounts, open **Authentication → Users**. To inspect or change policies, open **Database → Policies**. The database password is for direct database administration; it never belongs in Flutter.

## Run the Flutter app

The project URL and publishable key are stored in the ignored local file `supabase.local.json`. The publishable key is suitable for client apps. Never put a secret key, service role key, or database password in this file or in Flutter source.

From the project folder:

```powershell
flutter pub get
flutter run --dart-define-from-file=supabase.local.json
```

If you clone the repository to another computer, create your own `supabase.local.json` with `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from the Supabase **Connect** panel. The file is ignored by Git.

## Mobile email links

In **Authentication → URL Configuration → Redirect URLs**, add exactly `launchpad://auth-callback/`. Keep email confirmation enabled. Install and run the app on the phone, then request a **new** confirmation or password reset email and open it on that same phone. New emails should return to LaunchPad; reset links should open the new-password screen. Existing emails still contain their old redirect URL. Set **Site URL** to a reachable HTTPS landing page when one is published, instead of localhost; this is the fallback if a flow omits a redirect.

The `launchpad://` scheme is configured in Android and iOS, and the app passes it explicitly to Supabase for signup and reset. For a web deployment, add that site's HTTPS origin to Redirect URLs too. A mobile app does not require a hosted web app for its confirmation link to open the installed app.

## Map tiles and nearby discovery

The Radar tab requests device location, calls the `nearby_businesses` database
function, sorts businesses by distance, and displays markers on an interactive
Flutter map. It uses OpenStreetMap tiles when no token is supplied. To use
Mapbox tiles, create a **public** token with `styles:read` permission and add
`MAPBOX_PUBLIC_TOKEN` to the ignored `supabase.local.json`, or pass it with
`--dart-define=MAPBOX_PUBLIC_TOKEN=...`. Never place a secret Mapbox token in
the app. A business publishes its GPS position from **Settings → Business Map
Location**. Location permission, outdoor accuracy, and radius filtering still
require a physical-device test.

## PayMongo classroom payment API

Migration `supabase/migrations/202610110010_paymongo_payments.sql` is already
active in the hosted project. For a new Supabase project, apply it after
migration 009. It creates protected contract payments, requires funding before
a student can submit completion, and marks a paid test transaction as released
when the business approves the project.

Create a PayMongo account, switch to test mode, and save its `sk_test_...`
secret in Supabase as `PAYMONGO_SECRET_KEY`. Never place this secret in Flutter,
`supabase.local.json`, or GitHub.

The `create-paymongo-checkout`, `sync-paymongo-payment`, `paymongo-return`, and
`delete-account` Edge Functions are deployed. Keep JWT verification enabled on
the authenticated functions and disabled only on `paymongo-return` so
PayMongo's browser redirect can open it.
The app verifies the Checkout Session directly with PayMongo after returning;
it does not trust the browser redirect by itself.

## How signup works

1. A student or business registers in the app.
2. Supabase Auth creates the account. Database triggers create `profiles` and the matching role-specific profile. Student skill selections go into `student_skills`.
3. If email confirmation is enabled, the person must follow the email link and then sign in. The app does not assume signup also created a session.
4. Open **Authentication → Users** and then the corresponding tables to check the records.

The signup form can select only `student` or `business`; a client cannot request an admin role. The profile role and verification status are not editable by ordinary clients.

## Why this schema is in third normal form

- `auth.users` owns credentials. `profiles` owns fields shared by all people. `student_profiles` and `business_profiles` own only their role-specific fields.
- `skills` contains each skill once. `student_skills`, `job_skills`, and `portfolio_project_skills` link skills to their owners without comma-separated or array lists.
- Jobs reference a business. Proposals reference a job and a student. A contract references the winning proposal and stores an immutable snapshot of the agreed budget, timeline, and participants at acceptance. These snapshot fields intentionally preserve historical terms if the job or proposal changes later.
- Conversations, messages, and reviews reference the accepted contract. Conversation creation happens inside the acceptance transaction.
- Unique constraints allow one proposal per student and job, one accepted proposal per job, and one contract per job. `accept_proposal()` locks the job row and makes acceptance, the contract snapshot, and conversation creation one database transaction.

## Current development state

Supabase backs authentication, jobs, proposals, acceptance, profiles,
portfolios, saved jobs, contract chat, notifications, reports, reviews,
business locations, protected PayMongo payment records, contract deliverables,
verification documents, disputes, moderation, diagnostics, and account deletion.
Migrations through 016 are active in the hosted project. Verification remains
manual: an allowlisted administrator must approve every uploaded document.

Android push delivery uses the `send-push-notification` Edge Function. Its
Firebase service-account JSON and shared webhook secret are stored only as
Supabase secrets. The matching webhook secret is stored in Vault under
`launchpad_push_webhook_secret`; migration 014 connects every new notification
row to the sender without exposing either credential to the mobile app.

Email confirmation and password reset have configured mobile callbacks and a
reset-password screen, but still need a new email opened on the installed
Android app. Before a defense, test signup, role isolation, job CRUD, bidding,
acceptance, PayMongo checkout, chat, completion, reviews, notifications,
profile photos, verification upload, and direct-route protection with prepared
student and business accounts. The SQL rollback suites verify database rules
without retaining their test rows.
