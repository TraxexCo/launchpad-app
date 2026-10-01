# LaunchPad improvement backlog

This list records work that remains after the 1 October 2026 enhancement pass. Items are ordered by release risk. A feature is complete only after its acceptance check passes on a real device with two confirmed accounts.

## Apply before the next test run

| Priority | Action | Acceptance check |
|---|---|---|
| P0 | Run `supabase/migrations/202610010006_reports.sql` once in Supabase SQL Editor. | A signed-in user submits a report; it appears in `public.reports`; another ordinary user cannot read it. |
| P0 | Run `supabase/migrations/202610010007_marketplace_lifecycle.sql` once after migration 006. | Run `supabase/tests/marketplace_lifecycle_rollback.sql`; it reports that all lifecycle assertions passed. |
| P0 | Add `launchpad://auth-callback/` to Supabase Authentication redirect URLs. | A new confirmation email and reset email open the installed app. |
| P0 | Decide a permanent Android application ID and iOS bundle ID. | Release builds no longer use `com.example.launchpad_app`. |
| P0 | Create production signing credentials and store them outside Git. | A signed release APK or App Bundle installs and upgrades successfully. |

## Fix before claiming all scenarios pass

| Priority | Problem | Required fix and check |
|---|---|---|
| P0 | Several authenticated flows still lack real two-user device coverage. | Run registration, role isolation, job posting, proposal, acceptance, chat, notification, logout, and offline retry with one student and one business account. Record evidence per original test case. |
| P0 | Immediate-dashboard signup test conflicts with required email confirmation. | Update that test case to expect a confirmation screen, or deliberately disable confirmation and document the security decision. |
| P0 | Direct RLS deletion normally returns zero affected rows instead of HTTP 403. | Keep app deletion through the guarded RPC and correct the written test expectation. |
| P1 | Report records have no administrator review interface. | Add a separately provisioned administrator role, restricted queue, status changes, audit fields, and resolution notes. Never infer admin access from signup metadata. |
| P1 | Notification preferences filter the in-app inbox only. | Add push notification delivery and enforce preferences in the server-side delivery path before describing them as push settings. |
| P1 | Error messages sometimes expose raw Supabase text. | Map known database, authentication, timeout, and network errors to concise user messages while retaining diagnostic logs in development. |

## Enhance product workflows

| Priority | Enhancement | Acceptance check |
|---|---|---|
| Done after migration 007 | Contract completion workflow | Student requests completion, business confirms or requests changes, the related job closes on approval, and both users receive notifications. |
| Done after migration 007 | Reviews for both participants | Each participant can submit one review after completion; student ratings are calculated from reviews received. |
| Done after migration 007 | Portfolio skill editing | Owners can add and remove project skills; skill replacement runs in one protected database transaction. |
| Done after migration 007 | Proposal withdrawal | A student can withdraw only their own pending proposal; accepted and rejected proposals remain immutable. |
| P1 | Account deletion/export | Provide authenticated export and confirmed account deletion with documented retention behavior. |
| P2 | Search and pagination | Jobs, proposals, notifications, and portfolios remain responsive with hundreds of rows. |
| P2 | Accessibility | Test screen readers, text scaling, contrast, focus order, keyboard navigation, and 44-pixel touch targets. |
| P2 | Localization | Move visible strings into Flutter localization resources and add Philippine currency/date formatting. |

## Improve engineering and release quality

| Priority | Improvement | Acceptance check |
|---|---|---|
| P0 | Continuous integration | Every push runs formatting, `flutter analyze`, tests, and Android/web builds. Protected `main` requires successful checks. |
| P1 | Integration tests | Automate role guards, registration validation, proposal lifecycle, and deep-link recovery against an isolated test project. |
| P1 | Crash and diagnostic logging | Capture non-sensitive failures with environment and app version; never log tokens, passwords, message bodies, or private documents. |
| P1 | Database migration tracking | Adopt Supabase CLI migration history so dashboard changes and repository migrations cannot drift. |
| P1 | Dependency maintenance | Review outdated packages in small batches and retest instead of applying a bulk major-version upgrade. |
| P2 | Performance | Profile dashboard queries, image/network caching, rebuild counts, and startup time on a low-end Android device. |

## Remove or avoid

- Remove experimental ZIP archives and `scripts/` from the project directory after saving them elsewhere; they are intentionally not committed.
- Remove debug signing from release configuration before distribution.
- Remove sample names, invented ratings, fake delays, and success messages that are not backed by stored data. The tracked app source has been cleaned of the known instances; keep this rule for new screens.
- Avoid storing Supabase secret keys, database passwords, Mapbox secret tokens, signing keystores, or recovery links in Git or app source.
- Avoid calling a screen “nearby” until location permission, distance calculation, and an explicit radius are implemented and tested.
- Avoid publishing a privacy policy or support promise until the organization has approved the text and established a monitored contact channel.
