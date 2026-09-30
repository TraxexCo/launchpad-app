# LaunchPad test-case audit — 22 September 2026

**Historical baseline:** this audit records the state before the follow-up fixes. See [TEST_REMEDIATION.md](TEST_REMEDIATION.md) for current implementation and verification status.

Scope: the attached “LaunchPad Mobile Platform: Test Scenarios & Test Cases Specification” (TS-01 through TS-06, TC_AUTH_001 through TC_PORT_010). I treated every stated expected result as the acceptance criterion, including the exact screen behavior and database side effects. The source document cuts off in the middle of TC_PORT_010; its expected result is missing.

**Verdict rules:** **PASS** means the specified behavior was directly observed. **FAIL** means inspected implementation definitively contradicts at least one required step or result; a live test cannot make that case pass as written. **NOT VERIFIED** means code suggests a result, but the required live actors/data/device/network/fault injection were not available or not exercised. These are not passes. “Source” below means code/schema review, not an end-to-end run.

**Summary:** 60 cases reviewed — **1 PASS, 28 FAIL, 31 NOT VERIFIED**.

## Test execution and limits

- Ran `flutter analyze --no-pub` with SDK/Pub-cache access. It found **no errors in the app**; 31 warnings/info findings were confined to `scripts/test_client.dart` and `scripts/test_module1.dart`.
- Ran `flutter test --no-pub`: the single `test/widget_test.dart` **placeholder** passed (`expect(true, isTrue)`). This establishes nothing about the 60 specified cases.
- An earlier same-day browser check on the locally running web app observed unauthenticated `/business/post-job` redirect to `/onboarding` (TC_AUTH_008). No authenticated two-user end-to-end or device run was completed for this audit.
- Inspected the applied Supabase migration source and app source. SQL migrations 001–004 had previously returned “Success” in the project SQL Editor, but no controlled database row assertions, RLS probes, concurrency, or fault injection were executed for these cases.
- `scripts/test_module1.dart` is **not reliable evidence**: it checks only whether `signUp` returned a user for registration (not profile rows, skills, or redirect); its duplicate-email and weak-password requests omit required role metadata; and several catch blocks print PASS for any exception. I did not count those labels as test results.
- The sample emails and passwords in the attachment were not used. No accounts or jobs were created solely to manufacture passing results.

## TS-01 Authentication and access control

| ID | Verdict | Evidence against the written result / remaining test |
|---|---|---|
| TC_AUTH_001 | **FAIL** | Registration UI has no school/course fields; `AuthService.register` does not submit them. With email confirmation enabled it routes to sign-in, not the required dashboard. Student skills are seeded via migration 003, but this does not rescue the full case. |
| TC_AUTH_002 | **FAIL** | Business metadata/profile insertion exists, but with email confirmation required the UI routes to sign-in instead of the required dashboard. No actual account/row assertion was run. |
| TC_AUTH_003 | NOT VERIFIED | Supabase password sign-in and role routing exist; needs a confirmed test account and observed session/dashboard. |
| TC_AUTH_004 | **FAIL** | `SplashScreen._checkAuth` delays **2,000 ms before lookup**, so the stipulated dashboard arrival within **1.5 seconds** is impossible via that screen. Session restore itself was not timed. |
| TC_AUTH_005 | **FAIL** | Logout calls Supabase sign-out and navigates, but both dashboard logout controls and settings sign-out omit the required **confirmation prompt**. Business dashboard does not await sign-out. |
| TC_AUTH_006 | **FAIL** | Registration displays a generic snackbar from the exception; no 409-specific handling or inline error. Supabase duplicate-email behavior is configuration-dependent and was not probed. |
| TC_AUTH_007 | **FAIL** | The form requires **8** characters and says “At least 8 characters,” not the specified **6** and “Password must be at least 6 characters.” A five-character password is blocked, but the full expected result does not match. |
| TC_AUTH_008 | **PASS** | Earlier same-day local browser test: unauthenticated direct `/#/business/post-job` went to `/#/onboarding`. |
| TC_AUTH_009 | **FAIL** | Role guard redirects a student to `/student`, but it does **not show the required unauthorized alert**. Live cross-role navigation still needs checking. |
| TC_AUTH_010 | NOT VERIFIED | Supabase client parameterizes requests and schema uses text fields; Unicode input and rendered output were not exercised. |

## TS-02 Job management

| ID | Verdict | Evidence against the written result / remaining test |
|---|---|---|
| TC_JOB_001 | NOT VERIFIED | Create service inserts a job then job-skill rows; needs business account, UI submission, row checks, and dashboard check. The two inserts are not one transaction. |
| TC_JOB_002 | NOT VERIFIED | Browse screen loads jobs; two-user publication and next-load result were not exercised. |
| TC_JOB_003 | NOT VERIFIED | Edit service/UI exist; needs owned job, saved budget assertion, relation check, and visible refresh. |
| TC_JOB_004 | NOT VERIFIED | Delete service/UI and `job_skills` cascade exist; needs owned job and before/after row checks. |
| TC_JOB_005 | **FAIL** | Spec asks for category **“Web Dev”**; Browse Jobs chips include **“Web App”**, not “Web Dev”. Search/category filtering logic exists, but the specified interaction cannot be performed. |
| TC_JOB_006 | **FAIL** | Title gives “Title is required”; empty description gives **“Write at least 50 characters”**, not **“Description is required”**. Validation blocks progression before request. |
| TC_JOB_007 | **FAIL** | Form permits numeric `0` and `-500` past its validator. Service later rejects nonpositive values with **“Enter a valid budget”** / generic error, not the required “Budget must be greater than zero” form alert. PostgreSQL `budget > 0` check exists. |
| TC_JOB_008 | NOT VERIFIED | SQL `jobs_insert` checks `private.is_business`; an authenticated student direct insert needs an actual RLS probe. |
| TC_JOB_009 | **FAIL** | The RLS `DELETE` policy hides another business’s row from deletion, so a PostgREST delete without `.select()` can succeed with **zero affected rows**. The spec requires HTTP 403/RLS violation, which this policy/query does not guarantee. Needs a live probe for actual response. |
| TC_JOB_010 | NOT VERIFIED | Description is PostgreSQL `text` with no length cap; 25,000-character submission and UI overflow were not exercised. |

## TS-03 Proposals

| ID | Verdict | Evidence against the written result / remaining test |
|---|---|---|
| TC_PROP_001 | **FAIL** | Proposal insertion/success screen exist, but the job-detail button does not become the specified **“Proposal Submitted”** state on return. Full persisted row needs live check. |
| TC_PROP_002 | **FAIL** | `ProposalService.submitProposal` accepts `attachedProjectId`, but Submit Proposal screen has **no Attach Project picker** and never passes an ID. Business detail can display an attachment only if one is inserted by another means. |
| TC_PROP_003 | NOT VERIFIED | My Proposals reads rows and shows statuses/budgets; needs multiple real proposals and UI check. |
| TC_PROP_004 | **FAIL** | Business inbox loads proposals on screen initialization; no realtime subscription or dynamic counter listener is present. A newly submitted bid does not automatically update an already open inbox. |
| TC_PROP_005 | NOT VERIFIED | Status tab filters are implemented; needs mixed real proposals and observed tab behavior. |
| TC_PROP_006 | **FAIL** | Empty cover letter is blocked, but message is **“A cover letter is required”**, not the specified prompt. |
| TC_PROP_007 | **FAIL** | Rate validator flags letters, but says **“Enter a valid number”**, not “Enter a valid numeric amount”; numeric keyboard alone does not restrict all input. |
| TC_PROP_008 | **FAIL** | DB has `unique(job_id, student_id)`, but UI catches and displays the raw error; no required **“You have already submitted a proposal for this job”** banner. |
| TC_PROP_009 | NOT VERIFIED | SQL proposal INSERT RLS checks student role; needs business-token direct insert to prove enforcement. |
| TC_PROP_010 | **FAIL** | RLS rejects insertion after a job closes, but the client only shows raw error text; no required **“This job is no longer accepting proposals”** notification is mapped from the insert failure. No concurrent close was run. |

## TS-04 Contract lifecycle

| ID | Verdict | Evidence against the written result / remaining test |
|---|---|---|
| TC_CONT_001 | **FAIL** | `accept_proposal` updates job status to **`contracted`**; specification requires **`in_progress`**. Schema enum has no `in_progress` job value. Actual RPC not invoked. |
| TC_CONT_002 | NOT VERIFIED | RPC source rejects other pending proposals in the same function; needs three proposals and post-commit assertions. |
| TC_CONT_003 | **FAIL** | `contracts` has only `proposal_id`, status, and timestamps. No immutable agreed-rate/timeline snapshot or direct job/business/student IDs as specified. |
| TC_CONT_004 | **FAIL** | Schema has **no `conversations` table**; RPC inserts only into `contracts`. Chat uses contract ID directly. No conversation row can be created as written. |
| TC_CONT_005 | **FAIL** | Student proposals have accepted status treatment, but do not display the specified **“Active Contract”** card with direct **“Open Workspace / Chat”** action in that list. |
| TC_CONT_006 | **FAIL** | The function rejects another proposal for a contracted job, but raises **“This job is no longer accepting proposals”**, not the specified “Job is no longer open for acceptance”; job status is `contracted`, not `in_progress`. |
| TC_CONT_007 | **FAIL** | Ownership check exists, but exception text is **“Only the job owner can accept a proposal”**, not the required “Not authorized to manage this job.” No foreign-owner RPC call was run. |
| TC_CONT_008 | NOT VERIFIED | A student should fail ownership check, but function has **no explicit caller-role check**. Actual student RPC and exception were not observed. |
| TC_CONT_009 | NOT VERIFIED | RPC locks the job row `FOR UPDATE`; a simultaneous two-request race and resulting rows were not measured. |
| TC_CONT_010 | NOT VERIFIED | PostgreSQL function should be transactional, but the named **conversation insert stage does not exist**, so the specified fault cannot be injected. A replacement fault/rollback test was not run. |

## TS-05 Chat and live GitHub

| ID | Verdict | Evidence against the written result / remaining test |
|---|---|---|
| TC_CHAT_001 | NOT VERIFIED | Chat inserts sender/body/contract and renders own bubble; needs real contract and two-user row/UI check. It uses a contract channel, not the specified conversation channel. |
| TC_CHAT_002 | NOT VERIFIED | `messages.stream` and migration 002 publication exist; simultaneous two-device delivery was not observed. |
| TC_CHAT_003 | NOT VERIFIED | Public profile calls GitHub REST and builds cards; valid handle, response, language/stars display were not end-to-end checked. |
| TC_CHAT_004 | NOT VERIFIED | Language chip filter exists in source; needs repos in multiple languages and UI observation. |
| TC_CHAT_005 | NOT VERIFIED | Repository card uses `url_launcher` for GitHub URLs; system browser launch was not observed. |
| TC_CHAT_006 | NOT VERIFIED | `messages_read` RLS checks contract participation; needs third-user token querying a populated private contract. The policy is named `messages_read`, not `messages_read_policy`; name alone does not change behavior. |
| TC_CHAT_007 | NOT VERIFIED | Client trims and suppresses empty body; DB check also rejects blank text. A UI click and row-count assertion were not performed. |
| TC_CHAT_008 | **FAIL** | 404 becomes **“GitHub account not found.”** in profile error UI, not the specified **“No repositories found or user not found”** info card. It should avoid a crash, but full expected result differs. |
| TC_CHAT_009 | **FAIL** | Send failure shows raw exception snackbar; no specified **“Network error: unable to send message”** text and **no retry-marked bubble**. Airplane mode not run. |
| TC_CHAT_010 | **FAIL** | Service handles 403/429, but UI message is **“GitHub is temporarily limiting requests. Try again later.”**, not the required rate-limit wording. No injected 403 was run. |

## TS-06 Student portfolio

| ID | Verdict | Evidence against the written result / remaining test |
|---|---|---|
| TC_PORT_001 | NOT VERIFIED | Add form inserts portfolio row and navigates to detail; needs real student account, save, and row/screen observation. |
| TC_PORT_002 | NOT VERIFIED | Add form maps selected skill names to junction rows; needs multi-skill save and detail check. |
| TC_PORT_003 | NOT VERIFIED | Dashboard `FutureBuilder` queries student projects and builds a two-column grid; needs multiple persisted rows and UI observation. |
| TC_PORT_004 | NOT VERIFIED | Card routes to ID and detail queries skills; needs persisted project and navigation observation. |
| TC_PORT_005 | NOT VERIFIED | Detail URL helper checks HTTPS and calls `launchUrl`; real device/browser launch not observed. |
| TC_PORT_006 | **FAIL** | Blank title is blocked, but helper says **“Title is required”**, not required **“Please enter a title”**. |
| TC_PORT_007 | NOT VERIFIED | Add form validates repository URL and detail suppresses non-HTTPS launch; malformed input and browser behavior were not exercised. |
| TC_PORT_008 | NOT VERIFIED | Router redirects business from student route and portfolio INSERT RLS checks student identity; needs both live route and direct database probe. |
| TC_PORT_009 | NOT VERIFIED | Detail catches missing-row error and renders **“Could not load project: …”**; needs nonexistent-ID deep link and freeze/error observation. |
| TC_PORT_010 | NOT VERIFIED | **Specification is truncated** after “Tap and highlight every available skill chip (20+ chi…” and provides no expected result. App currently offers **16** seeded skills, so a 20+ chip action cannot be performed, but the missing acceptance criterion prevents a complete verdict. |

## Priority findings

1. Align the specification and implementation for the contract state/model: `jobs.status`, immutable contract snapshots, conversation provision, and acceptance error text. This affects TS-04 and chat setup.
2. Complete registration fields and settle the email-confirmation behavior; the stated immediate-dashboard result is incompatible with confirmation-required signups.
3. Add the missing proposal attachment picker, dynamic business inbox update, and explicit user-facing error mappings.
4. Align exact validation and fallback text where the test document requires it. These are test failures even where the underlying invalid operation is blocked.
5. Replace the placeholder test and misleading Module 1 script with assertions against actual rows/routes, using disposable confirmed student and business accounts. Then run multi-user, RLS, realtime, long-text, concurrency, offline, and fault-injection cases.

**Honest result:** only TC_AUTH_008 was directly observed passing. The other cases either have a definite specification mismatch (FAIL) or remain NOT VERIFIED. The green `flutter test` result is unrelated to the specified acceptance criteria.
