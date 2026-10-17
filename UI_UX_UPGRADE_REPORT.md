# LaunchPad UI and UX upgrade report

## Final design direction

LaunchPad uses the **Campus Utility** system: a graphite workspace with warm
ivory text and one coral action color. The application combines the scanability
of a local marketplace with the state clarity of a project tracker. Role is
communicated through labels, tasks, and navigation rather than competing color
palettes.

The shared visual signature includes a slim wayfinding rail, a restrained
blueprint grid on primary workspace headers, the LaunchPad arrow mark, compact
status labels, clear dividers, and task-specific page introductions. Motion is
limited to short route entrances, press feedback, state changes, and map marker
selection. Reduced-motion settings are respected by the shared entrance.

## System foundations

- Graphite canvas and layered neutral surfaces
- Coral `#FF6A3D` for primary actions and selection
- Manrope typography with a clear display, heading, body, and label hierarchy
- Four-pixel spacing base with 20-pixel phone gutters
- Ten-to-sixteen-pixel control and surface radii
- Semantic success, warning, error, and information colors
- Minimum 52-pixel primary actions and visible loading states
- Purposeful empty, loading, error, and offline states
- Shared profile photos with readable initials as a fallback

## Screen coverage

| Area | Final treatment |
|---|---|
| Splash and onboarding | Branded native splash, animated mark entrance, and role-first onboarding |
| Authentication | Labeled fields, inline validation, password recovery, progress, and role context |
| Student dashboard | Jobs, proposals, portfolio, profile, notifications, and nearby discovery |
| Job discovery | Search, categories, sorting, save state, business identity, and tailored empty states |
| Proposal flow | Guided form, attached portfolio evidence, review step, and clear submission feedback |
| Business dashboard | Job CRUD, proposal inbox, contract access, profile, and action-oriented empty states |
| Contract workspace | Payment state, timeline, deliverable history, revision messages, and completion actions |
| Chat and notifications | Realtime content, persistent failed-message retry, unread state, and safe destinations |
| Verification and settings | Private document upload, profile photo upload, preferences, GPS publishing, and account deletion |
| Administrator portal | Responsive web queues for verification, reports, disputes, accounts, jobs, and payments |
| Legal screens | Complete in-app classroom privacy notice and terms without broken external placeholders |

## Accessibility and interaction

- Semantic labels on reusable inputs, skill chips, notification controls, and
  editable profile photos
- Tooltips on icon-only actions
- Keyboard-safe forms and field-specific keyboard types
- Visible validation next to the field that needs correction
- Text wrapping, scrollable long content, and responsive admin layouts
- Explicit confirmation for destructive job, portfolio, notification, and
  account deletion actions
- Offline banner plus retryable loading and submission states

## Final hardware checks

The source implementation and automated checks cannot prove platform behavior
that depends on a real device or two simultaneous accounts. Before evaluation:

1. Install the final APK and complete one cold launch and session restore.
2. Test location permission granted, denied, and permanently denied.
3. Publish one business location and verify 5, 10, 25, and 50 km filters.
4. Open fresh confirmation and recovery emails on the installed application.
5. Complete a PayMongo test checkout and return to the correct contract.
6. Exchange realtime chat and notifications between student and business
   accounts; also verify background and terminated Android push delivery.
7. Upload, replace, and remove a profile photo and verification document.
8. Check every form with the keyboard open and at increased system text size.
