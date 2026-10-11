# LaunchPad Product Design System

## Design Read

LaunchPad is a two sided student and local business marketplace. It should feel useful, trustworthy, youthful, and grounded in real project work. It is a mobile product first. The web surface is reserved for administration.

Direction: **Campus Utility**. Think of a well designed campus bulletin board joined to a disciplined project tracker. Use direct language, obvious states, compact lists, and one unmistakable action color.

Design dials:

- Variance: 7/10
- Motion: 3/10
- Density: 6/10

## Reference Synthesis

- Marketplace browsing borrows the scanability and generous item separation found in mature consumer marketplaces.
- Contract, payment, and moderation surfaces borrow the compact hierarchy and state clarity found in strong productivity tools.
- Do not reproduce another brand's palette, typeface, components, or layout.

## Color Roles

- Canvas: `#101114`
- Surface: `#181A1F`
- Raised surface: `#202228`
- Muted surface: `#292C33`
- Hairline: `#34363D`
- Strong border: `#50535C`
- Primary ink: `#F6F3EA`
- Secondary ink: `#C7C6C2`
- Muted ink: `#92959D`
- Disabled ink: `#666A73`
- Brand action: `#FF6A3D`
- Brand action pressed: `#E9552B`
- Success: `#4FB286`
- Warning: `#E6A64C`
- Error: `#E06464`
- Information: `#6FA8DC`

The orange action color is the only brand accent. Student and business roles use labels, nouns, and icons instead of separate color systems. Semantic colors appear only when their meaning is required.

## Typography

- Family: Manrope for display, body, controls, and navigation.
- Technical identifiers may use JetBrains Mono, limited to payment references, contract numbers, and code.
- Display: 32/36, weight 750, tracking -0.8.
- Page title: 24/30, weight 700, tracking -0.3.
- Section title: 18/24, weight 700.
- Body: 15/23, weight 400.
- Supporting text: 13/19, weight 400.
- Labels: 13/18, weight 650.
- Avoid all caps except compact status and reference labels.

## Layout

- Base spacing unit: 4 px.
- Screen gutter: 20 px on phones, 28 px on tablets.
- Primary rhythm: 8, 12, 16, 24, 32, 48.
- Prefer lists separated by hairlines and whitespace. Use a card only when a group has its own action or state.
- Keep primary actions close to the content they affect.
- Never arrange 3 decorative icon boxes in a row. Metrics may use a plain aligned row without containers.

## Shape and Elevation

- Cards: 12 px radius.
- Inputs: 10 px radius.
- Buttons: 10 px radius.
- Status labels: 6 px radius, not pills.
- Bottom sheets and dialogs: 16 px radius.
- No opposing cut corners.
- No glow shadows. Use a 1 px hairline and surface contrast. Neutral lift shadows are allowed on interactive cards and overlays.

## LaunchPad Signature

- A slim left wayfinding rail marks primary workspaces, with one orange segment above a neutral track.
- Page introductions use a short orange rule, a strong title, and plain supporting copy.
- Role entry points pair one neutral icon tile with an editorial row composition.
- Interactive cards may use a restrained black lift shadow; static content remains flat.
- The orange mark uses a northeast launch arrow and a short baseline. Keep this symbol consistent across splash, onboarding, and sign in.
- Selected workspace headers use a faint blueprint grid and route line. This is the product's build and location motif, not a full-screen decoration.
- Warm graphite-to-rust gradients are reserved for major dashboard summaries. Never use the common purple-to-blue treatment.

## Components

### Buttons

- Primary: orange fill, dark ink, minimum height 52 px, exact action label.
- Secondary: transparent, strong hairline, primary ink.
- Destructive: error fill or error outline.
- Use one icon only when it improves recognition.
- Loading replaces the icon with a small progress indicator and preserves the label width.

### Cards and Rows

- Browsing results are rows or restrained cards with one hierarchy.
- Do not add an accent border to every card.
- Avoid gradients inside cards.
- Use status color only on the status element.

### Forms

- Persistent labels above or within the field.
- Inline validation explains the correction.
- Use the correct keyboard type and text action.
- Destructive actions require typed or explicit confirmation.

### Empty, Loading, and Error States

- Loading uses layout matched skeletons where practical. A spinner is acceptable only inside a button or compact blocking panel.
- Empty states state what is empty and name the action that fills it.
- Error states state what happened and give the next action.

## Motion

- Use motion for press feedback, route entrances, expanding details, and state changes.
- Duration: 120–220 ms.
- Do not fade each list item on scroll.
- Do not run decorative background loops.
- Respect reduced motion settings.

## Copy

- Use sentence case.
- Use active voice and exact verbs: “Submit deliverable”, “Fund project”, “Request revision”.
- Avoid slogans, developer syntax, fake terminal labels, buzzwords, and emojis in system messages.
- Use Philippine peso formatting for money and locale aware dates.

## Product Rules

- Mobile supports students and businesses.
- Web supports administrators.
- Contract state and the next action must be visible without opening chat.
- Payments must state that PayMongo is in test mode for the classroom demonstration.
- Verification documents are private and must never appear in public profile components.

## Avoid by Default

- Purple to blue gradients and gradients added without a content purpose.
- Gradient headline text.
- Mesh, grain, orbit, beam, or cursor following backgrounds.
- Glassmorphism.
- Low contrast gray text.
- Colored borders on every container.
- Excessive pill shapes.
- Repeated icon boxes.
- Fade in on scroll or staggered entrance animation.
- Inter everywhere.
- Decorative monospace labels.
- Generic “unlock”, “empower”, “seamless”, or “next level” copy.
