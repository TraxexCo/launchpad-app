# LaunchPad UI/UX Upgrade Report

## Design direction

LaunchPad now uses the custom **Night Mission** visual system. Its orbital field, animated scan line, signal nodes, clipped opposing corners, console typography, and electric role colors are based on the product idea: students and nearby businesses launching real local projects together. Student screens use orbit violet and electric cyan; business screens use launch mint and opportunity amber. Every screen keeps its own task-specific hierarchy inside this shared product identity.

The student dashboard is a **Flight Deck** centered on live missions, pitches, builds, Radar, and portfolio progress. The business dashboard is a separate **Business Control** view centered on open briefs, incoming signals, successful matches, and launching a new project brief. These are different page compositions rather than recolored copies.

## Verified mobile previews

- `docs/ui/night-mission-onboarding.png` — role selection at a 390 × 844 mobile viewport
- `docs/ui/night-mission-student-access.png` — student access state at the same viewport

## Screen-by-screen coverage

| Screen | Main UX treatment |
|---|---|
| Splash | Animated brand entrance and clear loading feedback |
| Onboarding | Role-first story, visual feature cards, and animated page progress |
| Login | Role-aware colors, clear validation, password recovery, and biometric-ready layout |
| Registration | Guided multi-step flow, progress feedback, role-specific fields, and validation |
| Password recovery | Secure visual focus, show/hide controls, live strength meter, and clear completion path |
| Student home | Personalized hierarchy, quick actions, live notification badge, activity summaries, and animated cards |
| Opportunity browser | Search, filters, sorting, animated results, pull-to-refresh, and tailored loading/error/empty states |
| Job details | Business trust context, structured project brief, skills, timeline, fixed pitch action, and recovery states |
| Submit proposal | Guided proposal composer, project attachment, live review step, validation, and submission feedback |
| My pitches | Stage tabs, summary metrics, pull-to-refresh, status cards, withdrawal flow, and tailored empty states |
| Add portfolio project | Structured project form, project type selector, skill picker, link validation, and fixed completion action |
| Project showcase | Portfolio case-study hierarchy, owner actions, external links, skills, and retryable loading states |
| Student public profile | Professional profile hierarchy, GitHub and portfolio sections, reviews, and resilient loading states |
| Business home | Hiring overview, job/proposal/contract summaries, live notification badge, and role-specific navigation |
| Post job | Guided brief builder, budget/timeline inputs, skills, preview step, and publish feedback |
| Edit job | Brief-quality guidance, grouped fields, role color treatment, and focused save action |
| Job proposals | Job summary, sort tools, animated candidates, pull-to-refresh, and useful empty/error states |
| Proposal details | Deep-link loading from the backend, candidate context, portfolio access, decision flow, and decision confirmation |
| Chat | Realtime project conversation, send/retry states, timestamped bubbles, and contextual first-message guidance |
| Notifications | Realtime unread state, per-event visuals, preferences, swipe deletion, mark-all-read, and role-specific empty copy |
| Settings | Account card, profile editing, notification controls synced to the backend, security, support, and business GPS publishing |
| Nearby Radar | Live device GPS, interactive OpenStreetMap, adjustable radius, business markers, distance ranking, and permission recovery |

## Interaction and accessibility improvements

- Minimum comfortable touch targets and visible pressed states
- Reduced-motion-friendly short transitions through standard Flutter animation APIs
- Keyboard-safe forms with clear inline validation
- Meaningful loading, empty, error, success, and disabled states
- Consistent back navigation and role-aware destination recovery
- Pull-to-refresh for frequently changing opportunity and proposal lists
- Realtime unread notification badge on both dashboards
- Clear permission recovery for device location access

## Backend-connected experiences

- Supabase authentication, password recovery, profiles, jobs, proposals, contracts, messages, reviews, reports, and notifications
- Proposal detail deep links now retrieve missing proposal data instead of depending on in-memory navigation data
- Cloud-synced notification preferences
- Realtime unread notifications and chat updates
- GPS publishing for business profiles
- Distance-sorted nearby business lookup through a database RPC
- Interactive map tiles from OpenStreetMap, so the Radar does not require a Mapbox token

## Phone validation checklist

The remaining checks require actual device hardware or platform services:

1. Grant, deny, and permanently deny location permission.
2. Verify GPS accuracy outdoors and refresh the Radar at 5, 10, 25, and 50 km.
3. Publish a business location from a business account, then confirm it appears for a nearby student.
4. Open the confirmation and recovery email links on Android and iOS.
5. Check keyboard behavior on every form at small and large text sizes.
6. Verify realtime messages and notifications using two signed-in phones.
7. Confirm contrast and tap comfort in bright outdoor conditions.

Background operating-system push notifications still require Firebase Cloud Messaging for Android and APNs for iOS. The current notification experience is realtime while the app is open and persists events in Supabase.
