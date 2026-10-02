# Project context

`smOrder` is the **requester's** app in the transport orders module - the
line foreman ("brygadzista") who asks for a transport and then watches it
happen. It is the other half of the lifecycle `../smVendor` (the forklift
operator) drives, on the same `orders` tables in `../wpsapi`. See that
repo's AGENTS.md, "Transport orders", for the data model.

| app | who uses it | what it does |
|---|---|---|
| `../wpsapi` | - | Express + Postgres backend. Owns all data. |
| `../wps` | office / supervisor | Next.js dashboard; also where a delivered order is accepted ("Zgadza się") or a problem reported. |
| `../smpda` | warehouse operator | Honeywell PDA: scans and issues the actual stock. |
| `../smVendor` | forklift operator | Takes an order, marks it delivered. |
| **`.` (smOrder)** | **line foreman** | **Places the six order types and tracks them to done/cancelled.** |

Targets **Android and web** (`flutter create --platforms android,web`) - no
iOS/desktop scaffolding. Mirrored file-for-file from `../smVendor` wherever
the shape matched (`core/api`, `core/session`, `theme/`), so changes worth
having in both usually apply the same way.

## What it does
**Two tabs** (`widgets/app_shell.dart`): "Zamawianie" and "Konto".
**Phone-first - bottom bar only**, with no side-nav variant for a wide
screen (smVendor and smpda do have one; this app deliberately does not).

### Zamawianie (`features/orders/orders_page.dart`)
- A list of orders with an **"Aktywne" / "Historia"** toggle - `active` is
  new + in_progress + problem + delivered, `history` is done + cancelled
  (wpsApi's own `STATUS_SETS`). History has to exist here: a cancelled
  order drops out of `active` the moment it is cancelled, so without it a
  reported problem would be unreachable. Polls every 5 s.
- **"Nowe zamówienie"** opens a **bottom sheet** (`showShadSheet`,
  `side: bottom`) listing the same six types wps's own menu offers, each in
  wps's own colour for that type (`order_types.dart`'s `iconColor`, hex
  values converted from Tailwind v4's oklch tokens). After a type is picked
  the sheet's slide-out is awaited before the form is pushed, otherwise the
  form covers the animation and the drawer looks like it vanished.
- Tapping an order opens `order_detail_page.dart`: live (3 s poll),
  read-only **except for the two answers this app owes** (see below). It
  shows the materials with how much has been issued, the photo if there is
  one, and a red "Zgłoszono problem" banner with the reason.
  take/deliver belong to smVendor. The step-by-step history
  (`GET /orders/:id/events`) is **deliberately not shown** - this screen is
  for what to do now; reconstructing an episode afterwards is wps's job.
- Items are shown with a ticked circle when fulfilled, **not** struck
  through or dimmed - a finished order must stay as legible as a pending
  one (smVendor's tile does strike through, because there it is a working
  checklist).

#### The two things this app answers
1. **A `delivered` order** - "Zgadza się" (`-> done`) or "Zgłoś problem"
   (`-> problem`, **not** `-> cancelled` as it was until 2026-10-01: a
   rejected delivery is not the end of the transport, it goes back to the
   forklift operator, who puts it right, marks it corrected and delivers
   again). A description is required. The footer is within thumb reach,
   with the countdown to the auto-accept. The remaining seconds come **from the server**
   (`autoAcceptInSeconds`) and are ticked down locally between polls, so a
   phone with a skewed clock cannot show the wrong deadline and the
   10-minute window stays a server-only constant.
2. **A `problem` order the operator reported** (`problemReportedFrom ==
   'inProgress'`, i.e. `awaitingProblemResolution`) - they cannot finish it
   and this person is who it waits on. The card in the list gets a red
   outline and "Wymaga Twojej reakcji" (this is how they find out at all -
   the user chose in-app only, no push), and the page offers **"Problem
   rozwiązany"** (`-> in_progress`, `OrdersApi.resolveProblem`) next to a
   disabled **"Czat"**. Chat is deferred, and shown-but-disabled on purpose:
   the pair is what makes resolving the obvious choice rather than the only
   one. Resolving sends the operator back to "Dostarczone"/"Zgłoś problem",
   so **the loop can run more than once on one order, from both sides**.

   A problem **this person reported** waits on the operator instead: the
   banner says so and there is no button, because only the side a report
   was made *to* may answer it.

### The form (`features/orders/new_order_page.dart`)
Fields are driven by `order_types.dart`'s per-type `fields` set, same
per-type shape as wps's own NewOrderPanel:
- `water_refill`: to + clean/dirty
- `material_order`: to + production order + items
- `spool_order`: to + items
- `goods_transport`: from + to, both free text with suggestions
- `waste_removal`: from + **photo**
- `warehouse_return`: from

**"Zamówienie materiału" is driven by the production order**
(`cip_materials_field.dart`): type the number - **a fragment or just the
ending, e.g. the last 6 digits, is enough** - and CIP's bill of materials
for it is listed, filtered to what this warehouse stocks
(`/cip-orders/materials/warehouse`). Tap a material to put it on the order.
Deliberately a list rather than wps's input-plus-suggestions: on a phone a
handful of rows is easier to hit. Whatever CIP resolves the fragment to is
written back into the field, so the order is stored under the real number.
`ItemPicker`'s catalog search box is therefore hidden for this type
(`showSearch: false`) and it only lists what was picked, with a quantity
field per row; every other items type still searches the whole catalog.

**This is the one place the operator's own CIP token is used** - every other
call authorizes with the shared API_TOKEN. So the stored session's token can
be genuinely stale, and `SessionNotifier.freshCipToken()` renews it before
use; a 401 from the lookup invalidates it and retries once before telling
the person to log in again.

### Photos
`photo_field.dart` - camera or gallery via `image_picker`, shrunk on the
device (`maxWidth` 1600, quality 70) so what goes up is web-sized. The file
is uploaded **after** the order exists, under its id
(`OrdersApi.uploadPhoto` -> `POST /orders/:id/photo`), because that is how
wpsApi keys it. A failed upload reports the attachment specifically and
keeps the order - it was placed, and the forklift operator can already see
it. Bytes rather than a path, because on web an `XFile` has no real path.

Offered on `waste_removal` only for now; wps offers one for
`goods_transport` and `warehouse_return` too, and adding either is one
entry in `order_types.dart` now that the whole upload path exists.

## Design: `../wps` is the reference
**Take after wps, and not only its palette.** One person moves between the
dashboard and this app during a shift, so the same order must read as the
same order in both. That means:
- Colour, typography and radius come from `theme/` (`app_colors.dart` mirrors
  wps's `app/globals.css` tokens hex-for-hex; the per-type order icons use
  wps's own per-type colours, converted from Tailwind v4's oklch).
- Copy wps's **patterns** too: bordered rounded cards on the `card`
  background, status as a coloured pill with the same per-status colours as
  its `STATUS_STYLES`, secondary text in muted foreground, label-left /
  value-right info rows.
- When a screen exists in wps, start from **its** structure and wording -
  the Polish labels included ("Zlecający", "Zrealizował", "Wydano",
  "Zgłoś problem") - then adapt the *interaction* for touch: bigger tap
  targets, a bottom sheet instead of a centered dialog, a tappable list
  instead of a type-ahead. Adapt how it is operated, keep the identity.
- Deviating is fine for a phone-specific reason, but say so in a comment -
  e.g. this app is bottom-bar only (phone-first), and its order items are
  not struck through because the screen is read-only, unlike smVendor's
  working checklist.

## Conventions
- **UI is `shadcn_ui`** on `package:flutter/widgets.dart`; Material is
  imported only for single names (`ThemeMode`, `TextInputAction`). No
  `MaterialApp` ancestor exists, so `material.dart` widgets like `Tooltip`
  or `IconButton` are unavailable - hand-roll from `ShadTheme` colours
  instead (`_Pill`, `_ScopeTab`, `_RemoveRowButton` do).
- **i18n is `slang`**: edit `lib/i18n/pl.i18n.json` / `en.i18n.json`, run
  `dart run slang`. Polish is the base locale.
- **No router**: `features/auth/auth_gate.dart` swaps login/shell off the
  session; nothing pushes the shell by hand, so logging out cannot leave a
  stale shell on the navigator stack.
- **The session is persisted** (`core/session/session_providers.dart`,
  SharedPreferences key `smorder.session`) - reopening the app lands on the
  order list, not the login screen. It is never expired out automatically;
  logging out is explicit, on the Konto page.
- **Per-device settings** are small SharedPreferences-backed providers:
  `locale_providers.dart`, `theme_providers.dart` (system/light/dark, picked
  on the Konto page).
- Live data is **plain REST polling**, same reasoning as smVendor's.

## Keyboard and system bars (`main.dart`)
Both wrappers sit inside `ShadApp`, so they cover every route pushed later.
- **`_AboveKeyboard`** pads the whole app by `MediaQuery.viewInsets.bottom`
  and strips that inset for everything below it. Android is already told to
  resize (`windowSoftInputMode="adjustResize"`), but that only makes it
  *report* the inset - Material's Scaffold is what normally turns it into
  padding, and these apps have none (shadcn_ui on
  `package:flutter/widgets.dart`), so the keyboard used to sit on top of
  whatever was at the bottom: the chat's send button, "Dostarczone", the
  problem footer. `removeViewInsets` matters: without it a scrolling field
  or a SafeArea counts the inset a second time and leaves a keyboard-sized
  gap.
- **`_SystemBars`** asks for dark status-bar icons on the light theme and
  light ones on the dark theme, reading the **resolved** brightness from
  `ShadTheme` so "system" lands on the right one. An app that asks for
  nothing gets light icons, which are invisible on this app's light
  background - the clock and the battery simply were not there.

## Configuration
`core/api/api_client.dart` has the wpsApi address hardcoded (the family's
LAN address). The shared bearer token is **not** in the source (public
repo): run/build with `--dart-define=API_TOKEN=...`.

## Running it
- Android: `flutter build apk --debug --dart-define=API_TOKEN=...` then
  `flutter install -d <device>`.
- Web: `flutter build web --dart-define=API_TOKEN=...` and serve
  `build/web` statically. Note `flutter run -d chrome|edge|web-server`
  **hangs on this machine** at "Waiting for connection from debug service"
  (seen with all three targets), which is why the static-build route is the
  documented one. On web the session lands in `localStorage`, so a reload
  stays logged in.
- `flutter analyze` must be clean.
