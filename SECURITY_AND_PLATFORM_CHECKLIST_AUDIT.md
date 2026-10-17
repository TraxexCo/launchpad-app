# LaunchPad mobile and admin web checklist audit

Audit date: 2026-10-17

This report compares the supplied mobile and web production checklists with the
current repository, built artifacts, deployed administrator portal, and recorded
test evidence. It uses five statuses:

- **PASS**: verified by source evidence and an appropriate automated, database,
  build, or browser check.
- **PARTIAL**: some required protections or states exist, but the full checklist
  item is not satisfied.
- **FAIL**: the current implementation contradicts or omits the requirement.
- **UNVERIFIED**: implementation may work, but the required measurement or
  platform test has not been performed.
- **N/A**: the item does not apply to the auth-walled administrator portal.

## Executive summary

Physical phone testing is **not** the only remaining work. The project has a
strong functional baseline, but the supplied production checklist exposes code,
configuration, and evidence gaps that remain before every item can be called a
pass.

Verified strengths include RLS-backed ownership checks, database-level admin
authorization, server-only payment and Firebase secrets, server-side PayMongo
status verification, protected verification/deliverable files, database input
constraints, an in-app account deletion entry point, responsive admin login at
320 px, clean analysis, 81 passing Flutter tests, and successful Android/web
builds.

The most important remaining items are encrypted auth/session storage on mobile,
complete deletion of uploaded Storage objects, payment request idempotency under
concurrency, API rate limiting, release obfuscation/signing, pagination and
offline caching, just-in-time notification permission, web CSP/frame protection,
keyboard focus support, and measured device/browser/performance testing.

No critical vulnerability was proven during this review. Two high-severity
hardening gaps and several medium-severity production-readiness gaps were found.

## Mobile checklist

### 1. Security and authentication

| Requirement | Status | Evidence |
|---|---|---|
| No hardcoded private secrets | **PARTIAL** | PayMongo, service-role, webhook, and Firebase service-account secrets are read from Supabase secrets in the Edge Functions. `supabase.local.json` is ignored. The tracked Firebase client key is public by design, but its Android package/SHA restriction cannot be verified from this repository. |
| Encrypted local storage | **FAIL** | `Supabase.initialize` uses the package default session persistence (`lib/main.dart:23`). Supabase Flutter 2.17.2 defaults to SharedPreferences on native and localStorage on web. Failed chat text is also stored in SharedPreferences (`lib/screens/shared/chat_screen.dart:48-68`). |
| Database-level access control | **PASS** | RLS is enabled on core tables and policies enforce owners/participants (`supabase/migrations/202609220001_launchpad_foundation.sql:188-202,227-295`). Admin mutations recheck `private.is_admin()` inside security-definer functions (`202610110012_admin_moderation.sql:53-137`). |
| HTTPS, rate limits, server validation, sanitization | **PARTIAL** | Supabase, Firebase, GitHub, Mapbox, and PayMongo use HTTPS. Database checks validate core records. Authenticated Edge Functions validate identities and IDs. There is no application-level rate limiter or CAPTCHA for auth/expensive endpoints, and exact TLS version is controlled by providers rather than the app. |
| R8/ProGuard and Flutter obfuscation | **FAIL** | Release Gradle config does not enable shrinking/minification and uses the debug signing key (`android/app/build.gradle.kts:29-33`). The verified APK was a debug build and was not built with `--obfuscate --split-debug-info`. |
| Just-in-time permissions | **PARTIAL** | Location is requested from the radar feature. Notification permission is requested during post-frame startup (`lib/main.dart:46-48`, `lib/services/push_notification_service.dart:59-65`) rather than after a user chooses to enable notifications. |

### 2. Data management and architecture

| Requirement | Status | Evidence |
|---|---|---|
| Offline-first cache and mutation queue | **FAIL** | The app has a connectivity banner and a failed-chat queue, but no SQLite/Drift/Isar cache for jobs, contracts, proposals, or profiles. Most screens require a live Supabase connection. |
| Pagination and lazy database loading | **FAIL** | Main jobs, notifications, proposals, contracts, deliverables, events, verification, reports, and disputes queries fetch all matching rows. Examples: `lib/services/job_service.dart:19-24`, `notification_service.dart:7-15`, `admin_service.dart:17-37`. Three admin lists have fixed limits, but no next-page flow (`admin_service.dart:39-59`). |
| Optimistic UI with rollback | **PARTIAL** | Some local toggles and message bubbles provide immediate feedback, but the pattern is not applied consistently across save/delete/moderation flows. |
| Idempotency and tap debouncing | **PARTIAL** | Async buttons disable while busy, the payments table has one row per contract, and completed checkouts are reused. Two concurrent checkout calls can still both create provider sessions because the provider request occurs after a read and before the database upsert (`create-paymongo-checkout/index.ts:62-82,130-134`); no provider idempotency key is sent. |
| Data minimization and permanent account deletion | **PARTIAL** | The authenticated deletion function deletes the Auth user and database rows cascade (`delete-account/index.ts:17-24`; foundation migration line 15). It does not explicitly remove the user's profile images, verification files, or deliverable objects from Supabase Storage before deletion. |

### 3. UI, UX, and visual design

| Requirement | Status | Evidence |
|---|---|---|
| Loading, empty, error/retry, populated states | **PARTIAL** | Shared state views and loading states exist on major flows, but not every data-driven screen uses all four explicit states or skeleton loading. Populated long-text behavior still needs device verification. |
| 48 dp touch targets and thumb reach | **PARTIAL** | Primary buttons are 56 dp and many icon buttons use 48 dp. Smaller gesture-only controls remain, including the 38 dp chat back control (`lib/screens/shared/chat_screen.dart:299-315`) and profile edit affordances that can inherit avatars smaller than 48 dp (`lib/widgets/profile_avatar.dart:74-80`). |
| Safe areas and keyboard awareness | **PARTIAL** | Major screens use SafeArea/AppBar and forms scroll, while 200% text, cutout, gesture navigation, and multiple keyboard tests remain unverified on devices. |
| Contrast, hierarchy, typography, light/dark/outdoor | **PARTIAL** | The design system is consistent and the dark palette has clear hierarchy. No automated contrast audit or outdoor test exists. Both `theme` and `darkTheme` point to the same dark design and `themeMode` is forced dark (`lib/main.dart:58-60`), so the requested light-mode test is not satisfied. |
| Micro-interactions and haptics | **PASS** | The shared button provides scale feedback, loading/disabled states, and haptics (`lib/widgets/app_button.dart:73-118`). Motion is kept short. |

### 4. Performance, testing, and release readiness

| Requirement | Status | Evidence |
|---|---|---|
| 60/120 FPS and no main-thread stalls | **UNVERIFIED** | No Flutter DevTools/profile-mode frame trace exists for a low-end device. Static inspection found no obviously large synchronous parsing job, but that is not a frame-budget measurement. |
| Controller/subscription cleanup | **PARTIAL** | Core controllers and notification subscriptions expose disposal, and inspected stateful screens generally dispose controllers. A full runtime leak/profile test has not been run. |
| Image sizing, compression, memory/disk caching | **FAIL** | Profile photos use raw `Image.network` without explicit decode dimensions or a disk-cache package (`lib/widgets/profile_avatar.dart:42-46`). The bundled brand image is about 473 KB in the web build. |
| Airplane mode, process death, 200% text | **UNVERIFIED** | These scenarios require physical-device or platform-level execution and remain open. |
| Crash reporting and analytics | **PARTIAL** | Global Flutter/platform errors are recorded to Supabase (`lib/main.dart:24-33`), but reporting only works after authentication, stores unsanitized error/stack strings (`crash_reporting_service.dart:5-15`), and has no ANR/device crash SDK or product analytics. |

## Administrator web checklist

The web build is an auth-walled internal administrator console. Client-side
rendering is a reasonable rendering strategy here; public marketing SEO and SSR
are not required for this scope.

### 1. Security and authentication

| Requirement | Status | Evidence |
|---|---|---|
| Server-only secrets | **PASS** | The browser receives only Supabase's publishable key and public Firebase/Mapbox client configuration. Payment, service-role, webhook, and FCM private credentials remain in Edge Function secrets. |
| HttpOnly/Secure/SameSite server session | **FAIL** | The static Flutter SPA uses Supabase Flutter's default browser localStorage session. Moving to an HttpOnly cookie requires a server/BFF session architecture; RLS limits the effect of tampering but does not remove XSS token theft risk. |
| XSS, CSRF, injection prevention | **PASS** | No raw DOM HTML sinks were found in app code. Flutter renders text rather than injecting HTML, Supabase calls are parameterized, and classical cookie-based CSRF is not applicable to bearer-header API calls. The payment return page escapes the generated deep-link attribute (`paymongo-return/index.ts:1-11`). |
| CSP, HSTS, anti-frame headers, CORS allowlist | **PARTIAL** | Firebase Hosting sets `nosniff`, referrer, and permissions policies (`firebase.json:15-41`). No CSP, `frame-ancestors`/X-Frame-Options, or HSTS is configured in the repository. Payment/account Edge Functions return `Access-Control-Allow-Origin: *` (`create-paymongo-checkout/index.ts:3-6`, `sync-paymongo-payment/index.ts:3-6`, `delete-account/index.ts:3-6`). |
| Data-layer authorization | **PASS** | Admin route guards are backed by RLS and database functions that call `private.is_admin()`; client-side hiding is not the security boundary. |
| Rate limiting and bot protection | **FAIL** | No application rate limiter, lockout policy, or CAPTCHA/Turnstile integration is present for login, recovery, or expensive calls. Provider defaults were not audited. |

### 2. Data, caching, and state

| Requirement | Status | Evidence |
|---|---|---|
| URL reflects tabs, filters, and pagination | **FAIL** | Admin tabs and queue state are held in Flutter widget state; the selected tab/filter is not encoded in query parameters, so refresh/back/bookmark cannot restore it. |
| Async server-state cache/revalidation | **FAIL** | Admin data is fetched directly into screen state with manual refresh; there is no deduplicating cache or stale-while-revalidate layer. |
| Rendering strategy | **PASS** | CSR is appropriate for this small, authenticated internal console. Public student/business web routes are blocked. |
| Payload minimization | **PARTIAL** | Admin queries select explicit columns. Payments/accounts/jobs have fixed limits, but verification/reports/disputes are unbounded and several mobile services use `select()` for all columns. |
| Payment/webhook signature and idempotency | **PARTIAL** | There is no PayMongo webhook accepting provider events. The app reads status directly from PayMongo using a server secret, which avoids trusting the browser return. Checkout creation still lacks a provider idempotency key/concurrency lock. The notification database webhook uses a shared secret (`send-push-notification/index.ts:76-89`). |

### 3. Responsive design and accessibility

| Requirement | Status | Evidence |
|---|---|---|
| Layout from 320 px upward | **PASS** | Live browser check at 320×720 found no horizontal overflow; the login content remained reachable through vertical scrolling. Desktop layout was also visually verified. Authenticated dashboard breakpoints still deserve a populated-data run. |
| Keyboard navigation and visible focus | **FAIL** | The shared primary `AppButton` is a `GestureDetector` plus `Semantics`, not a focusable Material button/action (`lib/widgets/app_button.dart:99-188`). It has no keyboard activation or focus-visible treatment. Similar gesture-only profile controls remain. |
| Semantic structure and ARIA-equivalent labels | **PARTIAL** | Flutter semantics labels, tooltips, field labels, and a live error region exist (`admin_login_screen.dart:166-220`). Flutter CanvasKit is not conventional semantic HTML and requires accessibility semantics activation; complete screen-reader behavior is unverified. |
| Hover, focus, active, disabled, loading | **PARTIAL** | Loading, disabled, and pressed states exist. The custom primary button has no distinct hover or keyboard-focus state. |
| Prevent layout shift | **PARTIAL** | Splash assets and app layout reserve dimensions, but no CLS trace has been collected. The HTML splash image uses CSS sizing rather than explicit width/height attributes (`web/index.html:122-125`). |

### 4. Performance, SEO, and deployment

| Requirement | Status | Evidence |
|---|---|---|
| Core Web Vitals | **UNVERIFIED** | No Lighthouse/PageSpeed run proves LCP <2.5 s, INP <200 ms, or CLS <0.1. |
| Code splitting and bundle analysis | **FAIL** | The release produces a single `main.dart.js` of about 3.70 MB plus CanvasKit downloads. No route-level lazy loading is configured. |
| Assets and font optimization | **PARTIAL** | Long-lived caching is configured for assets. The brand PNG remains about 473 KB; no WebP/AVIF variant or explicit font preload was found. |
| SEO and crawler control | **PARTIAL** | The admin entry has a unique title, description, and `noindex,nofollow` (`web/index.html:19-32`), which is correct for an admin portal. There is no `robots.txt`; canonical/OpenGraph/sitemap are N/A unless a public landing page is added. |
| Cross-browser, error boundaries, 404/500 | **FAIL** | Chrome/IAB was checked, but Firefox and Safari/iOS were not. Global error recording exists, but no custom `ErrorWidget.builder` fallback is configured. Firebase rewrites every unknown path to the SPA and there is no dedicated 404/500 experience. |

## Prioritized security and production findings

### LP-SEC-001 — High — Auth sessions use plaintext platform storage

- **Location:** `lib/main.dart:23`; Supabase Flutter 2.17.2 default
  `SharedPreferencesLocalStorage`/browser localStorage.
- **Evidence:** Initialization does not provide a custom encrypted
  `FlutterAuthClientOptions.localStorage`.
- **Impact:** A compromised/rooted device, local backup, or successful web XSS
  could expose a reusable access/refresh session.
- **Fix:** Implement a `LocalStorage` backed by Android Keystore/iOS Keychain for
  native builds. For the static web portal, either accept and document the SPA
  model with a strong CSP and short sessions, or move admin auth behind a server
  that issues HttpOnly Secure SameSite cookies.
- **Mitigation:** Short session lifetimes, MFA for administrators, CSP, and rapid
  token revocation.

### LP-SEC-002 — High — Account deletion can leave uploaded objects

- **Location:** `supabase/functions/delete-account/index.ts:21-24`.
- **Evidence:** The function deletes the Auth user only. Database rows cascade,
  but the function never lists/removes paths in `profile-images`,
  `verification-documents`, or `contract-deliverables`.
- **Impact:** A user can be told deletion succeeded while files remain in
  Storage; public profile-image URLs may continue to work.
- **Fix:** Before deleting Auth, enumerate owned objects using the service role,
  remove them from every user-owned bucket, verify removal, then delete the user.
- **Mitigation:** A scheduled orphan cleanup and a documented retention policy.

### LP-SEC-003 — Medium — Web response hardening is incomplete

- **Location:** `firebase.json:15-41`.
- **Evidence:** `X-Content-Type-Options`, Referrer-Policy, and
  Permissions-Policy exist; CSP and anti-framing policy are absent.
- **Impact:** An injection bug would have a larger blast radius, and the portal
  can be framed for clickjacking unless the hosting edge supplies unseen headers.
- **Fix:** Add a tested CSP compatible with Flutter/Supabase/Google Fonts and add
  `frame-ancestors 'none'` (or X-Frame-Options DENY). Verify deployed response
  headers after release.
- **False-positive note:** HSTS or CSP could be set outside this repository;
  runtime header verification was blocked by the audit environment's DNS.

### LP-SEC-004 — Medium — Wildcard CORS on privileged Edge Functions

- **Location:** `create-paymongo-checkout/index.ts:3-6`,
  `sync-paymongo-payment/index.ts:3-6`, `delete-account/index.ts:3-6`.
- **Evidence:** Each returns `Access-Control-Allow-Origin: *`.
- **Impact:** Any website can attempt browser calls with a captured bearer token;
  authentication/RLS still protect the operations, but origin isolation is lost.
- **Fix:** Echo only allowlisted origins, add `Vary: Origin`, keep native requests
  without an Origin working, and reject unexpected browser origins.

### LP-SEC-005 — Medium — Checkout creation is not concurrency-idempotent

- **Location:** `create-paymongo-checkout/index.ts:62-82,130-134`.
- **Evidence:** An existing payment is read, then a provider checkout is created,
  then the database row is upserted. Concurrent calls can pass the read together.
- **Impact:** Duplicate provider checkout sessions and ambiguous payment UX.
- **Fix:** Add a server-side idempotency record/lock before contacting PayMongo
  and send a deterministic provider idempotency key when supported.

### LP-SEC-006 — Medium — No explicit abuse controls

- **Location:** repository-wide; auth forms and Edge Functions.
- **Evidence:** No rate-limit, lockout, or bot-challenge integration was found.
- **Impact:** Brute force, spam, resource exhaustion, and avoidable API cost.
- **Fix:** Configure Supabase Auth rate limits/CAPTCHA and add per-user/IP limits
  to payment sync/creation, account deletion, reports, and upload paths.

### LP-SEC-007 — Medium — Sensitive failed messages are stored in plaintext

- **Location:** `lib/screens/shared/chat_screen.dart:48-68`.
- **Evidence:** Failed message bodies are stored as a SharedPreferences string
  list.
- **Impact:** Private project conversation text can remain readable on disk.
- **Fix:** Encrypt the queue with Keystore/Keychain-backed storage and remove it
  after successful send/sign-out/account deletion.

### LP-SEC-008 — Low — Crash payloads are not scrubbed

- **Location:** `lib/services/crash_reporting_service.dart:5-15`.
- **Evidence:** Raw `error.toString()` and full stack strings are sent to the
  database.
- **Impact:** URLs, record IDs, or accidental user data embedded in errors may be
  retained.
- **Fix:** Redact email, URL query, token, and identifier patterns; limit length;
  define retention and admin access rules.

## What remains before the professor check

### Code and configuration work

1. Encrypt the native Supabase session and failed-chat queue.
2. Make account deletion remove owned Storage objects.
3. Add payment idempotency/concurrency protection.
4. Configure auth/API rate limits and bot protection.
5. Add and verify CSP plus anti-frame headers; restrict Edge Function CORS.
6. Move notification permission to an in-context settings/onboarding action.
7. Add pagination to the main mobile and admin collections.
8. Add image decode sizing/caching and compress the brand asset.
9. Make shared gesture controls keyboard focusable and add visible focus/hover.
10. Add a web error fallback and deliberate not-found route.
11. Configure real release signing, minification, and an obfuscated release build.

### Execution evidence still required

1. Physical Android tests: airplane mode during requests, process death/resume,
   notification delivery/tap routing, location/radar, deep links, payment return,
   camera/gallery upload, and 200% text.
2. Two-account realtime run: student and business messaging, proposal update,
   contract lifecycle, revision, completion, dispute, and admin resolution.
3. Firefox and Safari/iOS browser runs with keyboard-only and screen-reader
   checks.
4. Lighthouse/Core Web Vitals and Flutter profile-mode frame/memory traces.
5. Live deletion test proving database rows and every Storage object disappear.

## Final verdict

The app is **functionally well advanced and demonstration-ready after a focused
final pass**, but it is not accurate to say that only physical phone testing is
left. Some supplied checklist requirements are intentionally production-grade
and exceed a classroom demo, yet they currently remain failures or unverified.
For the evaluation, present the verified passes as passes, the existing
`READY` scenarios as implemented but awaiting execution, and never describe the
unmeasured security/performance items as completed.
