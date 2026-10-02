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

## Mapbox

Create a **public** Mapbox token with `styles:read` permission in your Mapbox account. Add `MAPBOX_PUBLIC_TOKEN` to the ignored `supabase.local.json` file, or pass it using `--dart-define=MAPBOX_PUBLIC_TOKEN=...`. Never put a secret Mapbox token in the app. The Radar tab uses Mapbox Static Images to show business markers. A business can save its address, latitude, and longitude in **Settings → Business Map Location**. Businesses without coordinates remain in the directory list but cannot have a marker. The map is an image with zoom controls and list selection; it does not support drag gestures or device proximity yet.

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

Supabase backs authentication, jobs, proposals, acceptance, profiles, portfolios, saved jobs, contract chat, notifications, reports, completion approval, and reviews for both contract participants. Migrations 006 and 007 are active in the hosted project. Document verification remains intentionally unavailable until a private Storage bucket and a restricted reviewer workflow exist; accounts are never auto-verified.

Email confirmation and password reset have a mobile deep link and reset-password screen, but still need a real device test after the Redirect URL is allowlisted. Before a defense, test signup, email confirmation, roles, job posting, bidding, acceptance, chat, completion, reviews, notifications, and direct route protection on two devices or browsers. After migration 007, `supabase/tests/marketplace_lifecycle_rollback.sql` can verify the database lifecycle without retaining its test rows.
