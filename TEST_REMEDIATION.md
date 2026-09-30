# LaunchPad failed-case remediation — 22 September 2026

This follows the 28 failures in `TEST_AUDIT.md`. **Implemented** means the code or hosted schema has been changed, not that the complete end-to-end case has passed. The original PASS/FAIL audit is a historical baseline. I do not relabel an unrun scenario as passed.

## Changes and checks by case

| Case | Current state | Verification / remaining condition |
|---|---|---|
| TC_AUTH_001 | Student school/course fields and signup metadata/trigger added. | Widget test reached step 2 and found both fields; hosted migration applied. Immediate dashboard conflicts with enabled email confirmation; full signup not run. |
| TC_AUTH_002 | Business signup profile data already existed. | Immediate dashboard conflicts with enabled email confirmation; full signup not run. |
| TC_AUTH_004 | Removed artificial 2-second splash delay. | The 1.5-second target still needs a timed session-restore test on a device. |
| TC_AUTH_005 | All sign-out controls now ask for confirmation and await sign-out. | Authenticated UI test pending. |
| TC_AUTH_006 | Duplicate email exceptions now show a friendly message. | Supabase’s actual HTTP code and duplicate-email disclosure depend on Auth settings; live duplicate test pending. |
| TC_AUTH_007 | Form now uses the documented 6-character rule and exact helper text. | Boundary test passed for 5 and 6 characters; widget test observed inline error. |
| TC_AUTH_009 | Cross-role redirect now carries an unauthorized alert to the destination dashboard. | Two-role route test pending. |
| TC_JOB_005 | Added “Web Dev” to publishing and browse filters. | Search/category UI test with multiple jobs pending. |
| TC_JOB_006 | Empty description now says “Description is required”; short nonempty text retains length warning. | Boundary test passed. |
| TC_JOB_007 | Form and service reject zero/negative budgets; negative sign is no longer stripped by parsing. | Boundary test passed for 0, -500, and 25,000. |
| TC_JOB_009 | App deletion now calls a guarded RPC that raises a permission error for another owner. | Rollback-scoped hosted SQL test proved a nonowner receives `insufficient_privilege` and cannot remove the row; owner deletion and related-proposal cascade also passed. Direct PostgREST table DELETE under RLS still returns zero affected rows rather than necessarily HTTP 403; the document’s direct-RLS expectation cannot be guaranteed by PostgreSQL RLS alone. Two-business HTTP test pending. |
| TC_PROP_001 | Job detail now checks existing proposal and shows disabled “Proposal Submitted”; success page links back to that job. | RPC insertion/assertions passed in a rollback-scoped database test; UI pending. |
| TC_PROP_002 | Added saved-project picker and passes `attached_project_id` to the submission RPC. | End-to-end attachment/reviewer test pending. |
| TC_PROP_004 | Published `proposals` to Supabase Realtime; home and inbox subscribe and reload on changes. | Two-user live update/counter test pending. |
| TC_PROP_006 | Exact empty-pitch prompt implemented. | Boundary test passed. |
| TC_PROP_007 | Exact nonnumeric-rate prompt implemented. | Boundary test passed. |
| TC_PROP_008 | Submission RPC maps the unique violation to the required duplicate message. | Rollback-scoped hosted database assertion passed; snackbar display pending. |
| TC_PROP_010 | Submission RPC locks and checks job status, returning the required closed-job message. | Rollback-scoped hosted database assertion passed; concurrent UI scenario pending. |
| TC_CONT_001 | Job status renamed `in_progress`; acceptance RPC sets it. | Hosted catalog and rollback-scoped acceptance assertion passed; owner UI pending. |
| TC_CONT_003 | Contract now stores job/participants and immutable agreed budget/timeline snapshot. | Hosted schema and rollback-scoped row assertion passed. |
| TC_CONT_004 | Conversation table added; acceptance RPC inserts one in the same transaction. | Hosted schema and rollback-scoped row assertion passed; chat UI pending. |
| TC_CONT_005 | Accepted proposal card now shows “Active Contract · Open Workspace / Chat” and opens chat. | Student UI pending. |
| TC_CONT_006 | Repeat acceptance now returns “Job is no longer open for acceptance.” | Rollback-scoped hosted database assertion passed. |
| TC_CONT_007 | Foreign-owner error changed to “Not authorized to manage this job.” | Second-business RPC test pending; only one business profile exists. |
| TC_CHAT_008 | GitHub 404 now gives the required info-card text. | Mocked 404 service test passed; profile UI pending. |
| TC_CHAT_009 | Failed send now shows the required network snackbar and a retryable bubble. | Airplane-mode/two-device test pending. |
| TC_CHAT_010 | GitHub 403/429 now gives the required rate-limit message. | Mocked 403 service test passed; profile UI pending. |
| TC_PORT_006 | Blank title now says “Please enter a title.” | Boundary test passed. |

## Verification completed

- Hosted migration `202609220005_contract_lifecycle.sql`: SQL Editor reported success. Catalog check showed `{open,in_progress,closed}`, all five snapshot columns, conversation table, and proposal RPC.
- Hosted rollback-scoped tests in `supabase/tests/`: contract acceptance/status/snapshot/conversation/re-acceptance assertions passed; proposal creation/duplicate/closed-job assertions passed; guarded deletion/permission/cascade assertions passed. Follow-up query found **zero** leftover audit jobs.
- `flutter build web --dart-define-from-file=supabase.local.json` succeeded after the final app changes.
- `flutter test --no-pub` passed the focused validation and mocked GitHub tests, and `test/registration_form_test.dart` passed an inline-error/second-step widget check. The old `expect(true, isTrue)` placeholder was removed.
- `flutter analyze --no-pub lib test` reported **no issues**. Full-repository analysis still reports warnings/info in the pre-existing experimental `scripts/` files.

## Remaining limits

The two immediate-dashboard registration cases conflict with the current requirement to confirm email ownership. They remain **FAIL** against the written test case while confirmation stays enabled. Existing confirmed test accounts or controlled account creation are required for the authenticated UI, cross-role, RLS, two-user realtime, and offline checks. The document’s HTTP 403 claim for a direct RLS-filtered DELETE does not describe normal PostgREST behavior; the new RPC supplies an explicit permission error for the app action.

## Additional work after this audit

- Signup and password reset now specify a mobile callback; Android and iOS register the `launchpad://auth-callback/` scheme. Password recovery now has an in-app form. This is **not yet a pass**: the redirect URL must be added in Supabase and a new email must be opened on an installed app.
- The student portfolio can import a displayed public GitHub repository and checks for an existing repository URL before insertion. It still needs a signed-in device test.
- The Radar tab uses Mapbox Static Images with real stored business coordinates and no mocked results. It needs a public Mapbox token and business coordinates. This is a selectable static map with zoom controls, not full drag navigation or geolocation. It is **not yet a pass** for any proximity or interactive-map test case.
