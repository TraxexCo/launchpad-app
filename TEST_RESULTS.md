# LaunchPad test status

Core suite tested on 2026-10-02 against Supabase project `oboyvpcziyjydyfguucs`; UI, location, and notification upgrades rechecked on 2026-10-05.

Status meanings:

- **PASS**: exercised by an automated Flutter, browser, build, or live rollback database test.
- **READY**: the implementation is present and inspected, but the exact scenario still needs a real device, email inbox, external browser, offline network, or a second simultaneous account.
- **SPEC**: the written expected result must be corrected before the case can pass honestly.

## TS-01 Authentication and role access

| Case | Status | Evidence or remaining check |
|---|---|---|
| TC_AUTH_001 | SPEC | Student signup and skill seeding are implemented. With email confirmation enabled, the correct result is the confirmation screen/login first, then the dashboard after confirmation. |
| TC_AUTH_002 | SPEC | Business signup is implemented. The same confirmation requirement applies. |
| TC_AUTH_003 | READY | Supabase password sign-in and role routing are implemented; requires a real confirmed account run. |
| TC_AUTH_004 | READY | Session restore is implemented; force-close timing requires a physical device. |
| TC_AUTH_005 | READY | Sign-out, confirmation, and navigation reset are implemented; final device run remains. |
| TC_AUTH_006 | READY | Duplicate-account error mapping is implemented; requires a disposable real email account. |
| TC_AUTH_007 | PASS | Flutter test and built-web browser test both display the required six-character validation. |
| TC_AUTH_008 | PASS | Built-web deep-link smoke test redirected `/business/post-job` to onboarding while signed out. |
| TC_AUTH_009 | READY | Cross-role GoRouter guard is implemented; requires authenticated student browser/device session. |
| TC_AUTH_010 | READY | Supabase parameterized writes and Unicode-safe Dart strings are used; requires disposable account input. |

## TS-02 Job management

| Case | Status | Evidence or remaining check |
|---|---|---|
| TC_JOB_001 | READY | Job and skill writes are implemented with missing-skill protection; full signed-in UI run remains. |
| TC_JOB_002 | READY | Feed reload behavior is implemented; simultaneous student/business observation remains. |
| TC_JOB_003 | READY | Owned job update and skill replacement are implemented; signed-in UI run remains. |
| TC_JOB_004 | PASS | Live rollback test verified guarded deletion and cascading proposal cleanup. |
| TC_JOB_005 | READY | Category, keyword, and sort filtering are implemented; authenticated UI run remains. |
| TC_JOB_006 | PASS | Required-field validators are covered by Flutter tests and analyzer checks. |
| TC_JOB_007 | PASS | Zero, negative, and nonnumeric budget validation is covered by Flutter tests and the database constraint. |
| TC_JOB_008 | PASS | Live authenticated-role RLS test denied a student job insert. |
| TC_JOB_009 | SPEC | Live RLS test returned zero affected rows for a foreign direct delete; the guarded `delete_job` RPC returns an explicit permission error. Expecting HTTP 403 from every PostgREST DELETE is inaccurate. |
| TC_JOB_010 | READY | PostgreSQL `text`, scrollable views, and wrapping are used; a 25,000-character device rendering run remains. |

## TS-03 Proposals

| Case | Status | Evidence or remaining check |
|---|---|---|
| TC_PROP_001 | PASS | Live rollback RPC test created a pending proposal with the expected rate and timeline. |
| TC_PROP_002 | READY | Attached project persistence and business navigation are implemented; two-role UI run remains. |
| TC_PROP_003 | READY | Student proposal list and status decoration are implemented; populated UI run remains. |
| TC_PROP_004 | READY | Business proposal realtime subscriptions are implemented; two-client observation remains. |
| TC_PROP_005 | READY | All, pending, accepted, and rejected tab filters are implemented; populated UI run remains. |
| TC_PROP_006 | PASS | Empty and short pitch validation is covered by Flutter tests. |
| TC_PROP_007 | PASS | Nonnumeric rate validation is covered by Flutter tests. |
| TC_PROP_008 | PASS | Live RPC test returned the required duplicate-proposal message. |
| TC_PROP_009 | READY | Student-only proposal policy and RPC role check are present; direct authenticated business call remains. |
| TC_PROP_010 | PASS | Live RPC test rejected submission after the job entered `in_progress` and left clean state. |

## TS-04 Contract lifecycle

| Case | Status | Evidence or remaining check |
|---|---|---|
| TC_CONT_001 | PASS | Live `accept_proposal` rollback test verified accepted proposal and `in_progress` job. |
| TC_CONT_002 | READY | Competing-proposal rejection is in the same transaction; project currently has only one student account for live testing. |
| TC_CONT_003 | PASS | Live test verified the immutable rate and timeline snapshot in `contracts`. |
| TC_CONT_004 | PASS | Live test verified automatic conversation creation. |
| TC_CONT_005 | READY | Realtime proposal publication and accepted UI state are implemented; second-client run remains. |
| TC_CONT_006 | PASS | Live test rejected re-acceptance with the required closed-job error. |
| TC_CONT_007 | READY | Foreign-owner check exists in the RPC; project currently has only one business account for live testing. |
| TC_CONT_008 | READY | Student role check exists in the RPC; authenticated student invocation remains. |
| TC_CONT_009 | READY | `FOR UPDATE` locking and one-contract/one-accepted indexes are present; a true concurrent two-request run remains. |
| TC_CONT_010 | READY | All operations are inside one PostgreSQL function transaction; controlled mid-transaction fault injection remains. |

## TS-05 Chat and GitHub

| Case | Status | Evidence or remaining check |
|---|---|---|
| TC_CHAT_001 | READY | Message insert and sent-bubble rendering are implemented; active-contract device run remains. |
| TC_CHAT_002 | READY | Supabase realtime stream is implemented and messages are in the realtime publication; two-client run remains. |
| TC_CHAT_003 | READY | GitHub REST parsing and repository cards are implemented; live profile run remains. |
| TC_CHAT_004 | READY | Language-chip filtering is implemented; live multi-language profile run remains. |
| TC_CHAT_005 | READY | HTTPS external launching is implemented; system-browser handoff requires a device. |
| TC_CHAT_006 | PASS | Live authenticated-role RLS test returned zero private messages for an unrelated user. |
| TC_CHAT_007 | READY | Whitespace suppression is implemented before insert; active-chat UI run remains. |
| TC_CHAT_008 | PASS | Mocked GitHub 404 test produced the required friendly message. |
| TC_CHAT_009 | READY | Network error bubble, snackbar, and retry action are implemented; airplane-mode run remains. |
| TC_CHAT_010 | PASS | Mocked GitHub 403 rate-limit test produced the required friendly message. |

## TS-06 Portfolio

| Case | Status | Evidence or remaining check |
|---|---|---|
| TC_PORT_001 | READY | Project insert and direct detail navigation are implemented; authenticated UI run remains. |
| TC_PORT_002 | READY | All selectable skills now exist in the live database and missing links fail loudly; multi-chip UI save remains. |
| TC_PORT_003 | READY | Two-column portfolio grid is implemented; populated device rendering remains. |
| TC_PORT_004 | READY | Detail route, joined skill query, and business access are implemented; two-role UI run remains. |
| TC_PORT_005 | READY | HTTPS repository launching is implemented; system-browser handoff requires a device. |
| TC_PORT_006 | PASS | Required-title validation is covered by Flutter tests. |
| TC_PORT_007 | READY | Create/edit validators reject non-HTTPS URLs and detail launch suppresses them; device UI run remains. |
| TC_PORT_008 | PASS | Live authenticated-role RLS test denied business portfolio creation; router also blocks the student route. |
| TC_PORT_009 | READY | Missing rows render `Could not load project`; direct deep-link UI run remains. |
| TC_PORT_010 | SPEC | The supplied test case is truncated. Implemented expected result: all 28 chips can be selected, persisted, and wrapped without silent loss. Live catalog and duplicate assertions pass. |

## Verification completed

- `flutter analyze --no-pub lib test`: no issues.
- `flutter test --no-pub`: 11 of 11 tests passed, including GPS distance calculations.
- Release web build with Supabase configuration: passed.
- Android debug APK build with Supabase configuration: passed.
- Built-web smoke test: onboarding rendered, signed-out protected route redirected, and weak-password error rendered.
- Live database rollback suites passed: contract acceptance, proposal errors, guarded deletion, marketplace lifecycle, skill catalog, and direct RLS isolation.

The remaining **READY** cases are not known failures. They are cases whose exact external behavior cannot be claimed as passed until the stated device, inbox, network, or simultaneous-account run is performed.

## 2026-10-05 upgrade verification

- Dart static analysis after the full screen-by-screen UI pass: **PASS, no issues**.
- Live GPS permission handling, distance calculation, map markers, radius controls, and business coordinate publishing: **implemented**.
- Proposal notification deep links now fetch proposal details from Supabase when navigation memory is unavailable: **implemented**.
- Realtime unread badge and cloud notification preferences: **implemented**.
- Location and notification preference migration plus rollback tests: **ready to run in Supabase**. The dashboard was unreachable during the final deployment attempt, so this is not marked live.
- Android rebuild: Gradle reached dependency resolution, then the network timed out while downloading Android and Kotlin artifacts. The previous Android debug build remains a pass; this upgraded dependency set still needs one successful rebuild when Maven and Google repositories are reachable.
