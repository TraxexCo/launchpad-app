# LaunchPad final examination backlog

This list contains only work that remains after migrations 001 through 016,
the administrator portal, Android push setup, PayMongo integration, profile
photos, and the Campus Utility redesign.

## Required before the final examination

| Priority | Remaining work | Passing evidence |
|---|---|---|
| P0 | Install and launch the final APK on the presentation phone | Cold launch, sign-in, session restore, and relaunch complete without a blocking crash |
| P0 | Run the full student and business workflow | Job CRUD, proposal, acceptance, contract, PayMongo test payment, chat, deliverable, revision, completion, and review are recorded |
| P0 | Verify mobile callbacks | Fresh confirmation and password-recovery emails open the installed application; PayMongo returns to the intended contract |
| P0 | Verify Android push | Foreground, background, and terminated-app notifications arrive and open a permitted destination |
| P0 | Verify GPS and nearby discovery | Permission states work; a published business appears at the expected distance and radius |
| P0 | Validate administrator access | Prepared administrator credentials open the web portal and can review one disposable verification submission |
| P0 | Complete the evidence matrix | Every test case has date, build, actual result, status, and evidence reference |
| P0 | Prepare the final documentation | System overview, setup, architecture, data flow, API notes, test results, and demonstration script match the final build |

## High-value polish if time remains

| Priority | Improvement | Acceptance check |
|---|---|---|
| P1 | Add integration tests | Auth guards and one core marketplace lifecycle run automatically against an isolated test project |
| P1 | Add continuous integration | Every push runs formatting, analysis, Flutter tests, and Android and web builds |
| P1 | Test accessibility | Screen reader, increased text size, contrast, focus order, keyboard behavior, and touch targets pass on the target phone |
| P1 | Test performance | Dashboard, map, images, and long lists remain responsive on the presentation phone |
| P2 | Add release signing | A signed release APK or App Bundle installs and upgrades successfully |
| P2 | Add iOS notification delivery | APNs and an iOS device are configured and tested |

## Written test corrections

- Registration cases must expect email confirmation before the first dashboard
  when confirmation is enabled.
- A direct Row Level Security filtered delete may affect zero rows rather than
  return HTTP 403. The guarded `delete_job` RPC supplies the explicit app error.
- `TC_PORT_010` in the original test specification is truncated and must be
  completed before printing.
- Cases marked `READY` are implemented but remain unpassed until their stated
  external or physical-device behavior is executed.

## Keep out of the submission

- Local ZIP archives, temporary deployment folders, generated scratch output,
  service credentials, database passwords, recovery links, and signing keys
- Claims that physical-device, email, payment-return, GPS, or background-push
  scenarios passed without recorded execution evidence
- Old Night Mission screenshots or descriptions that conflict with the final
  Campus Utility interface
