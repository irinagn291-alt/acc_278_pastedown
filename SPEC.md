# Pastedown — Build Specification

> Portfolio app 132, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Keep quotes from books you no longer own and paste one a day into a growing poem.

| Field | Value |
| --- | --- |
| Product name | Pastedown |
| Bundle identifier | `com.pastedown.cento` |
| Domain | https://pastedown-cento.pro |
| Contact URL | https://pastedown-cento.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `pdn_` |
| User-Agent | `Pastedown/1.0 (iOS; +https://pastedown-cento.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Pastedown -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A reader pastes a kept quote onto today's cento board so the line outlives the book it came from.

### 2.1 User flow

1. On the cento board, tap a cutting in the drawer rail and tap Paste — the quote lands as a cut-paper strip at the foot of today's poem.
2. Tap Paste again with a cutting from the same volume as the foot strip: the strip shivers, nothing lands, and a ClashMark ticks in the board's corner tally.
3. Pick a cutting from a different volume and Paste — it lands, and the poem is now three strips tall.
4. Open Cuttings, type a quote by hand, set its page number, and attach it to a Volume; it enters the drawer as Fresh.
5. Open Volumes, tap Scan, hold the back of the book being given away until the ISBN latches, let the title and maker fill in, then mark the Volume Gone with a reason of Sold, Lent, Lost or Culled — its cuttings stay.
6. Peel lifts the newest strip off the board and returns that cutting to the drawer as Fresh.
7. Next morning the board is bare: yesterday's cento sealed at midnight and now hangs in the Gathering as a collage tile, and the strips it holds are Spent.

### 2.2 Essential behaviour

- Cento board as home, drawn in CALayer: every strip is a CAShapeLayer with a torn cut-paper edge, its own paper tint, a slight seat angle and a soft paste shadow; the board scrolls as one canvas and the drawer rail sits under it.
- Cuttings drawer: hand-typed quote text plus page number and an attached Volume; a Cutting is Fresh, Pasted or Spent, and Spent cuttings sink to the bottom of the drawer and cannot be pasted again.
- Volumes sheet: create a Volume by typing, or by scanning its ISBN barcode before the book leaves; mark it Gone with a reason and a date, and its cuttings survive the volume — strips from a Gone Volume render with the title punched out of the paper.
- Adjacent-volume ban enforced by one pure predicate, with a ClashMark tally on the board and a full list of clashes in the Gathering.
- Midnight seal keyed by daykey: two or more strips seal the day's cento read-only; one strip or none writes Scrap and returns the strips to the drawer.
- Gathering: sealed centos as a paper-cut collage wall, plus counts of lines that outlived their book, volumes gone, longest cento and consecutive sealed days.
- Peel as a single-step undo on the board, and a plain-text copy of any sealed cento with its per-line volume attributions.
- Fully offline after the one ISBN lookup: no account, no sync, nothing leaves the device.

---

## 3. Uniqueness assignment for Pastedown

| Axis | Assigned value |
| --- | --- |
| Architecture | **Append-only paste-up (a Cento is an ordered array of CuttingIDs and is never mutated in place; Cutting and Volume are flat Codable records held in two side tables; the poem is derived by reduce at render, so a strip's text is stored once; legality is one pure predicate canFollow(foot, next) comparing volumeID; Paste appends, Peel drops the tail, Seal freezes the array under its daykey and stamps its cuttings Spent; a board with no strips renders Blank)** |
| UI approach | **UIKit CALayer manual drawing · canvas-first** |
| Naming convention | **Cento / florilegium lexicon (Volume, Cutting, Strip, Cento, Drawer, Gathering, ClashMark, SealMark, Scrap)** |
| File organization | **By cento role (Cento, Strip, Cutting, Drawer, Volume, ClashMark, SealMark)** |
| Dependency strategy | **None (zero external dependencies) — no SPM entry, nothing vendored; UIKit, AVFoundation and URLSession only** |
| Design direction | **opencode-ai · asymmetric-split · branded** |
| Typography | **SF Pro (system default) — strip text set in SF Pro Text at generous line spacing with optical kerning, the foot counter in SF Pro Display with monospaced digits, and no second face anywhere** |
| Navigation pattern | **Cento-locked chrome (the paste-up board never leaves home; Cuttings, Volumes, Gathering and Settings arrive as sheets over it; scan and search fuse inside Volumes)** |
| AI art style | **Paper cut origami collage · abstract** |
| Functional twist | **Adjacent-volume ban (a Cutting may not be pasted under a Strip from the same Volume; the ban writes a ClashMark and the foot keeps its line; a Cutting already pasted into a sealed Cento is Spent)** |
| Persistence | **UserDefaults+Codable — one Codable root under the key cento.store.v1 holding volumes, cuttings and centos as three flat arrays; centos store only CuttingIDs so a quote's text exists once; writes are debounced half a second** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — book_quotes

**Core** — A reader pastes a kept quote onto today's cento board so the line outlives the book it came from.

**Audience** — Library borrowers, book-swappers and people who cull their shelves — commonplace-book keepers who lose the volume but want the lines to survive, on one device, with no account.

**User flow**

1. On the cento board, tap a cutting in the drawer rail and tap Paste — the quote lands as a cut-paper strip at the foot of today's poem.
2. Tap Paste again with a cutting from the same volume as the foot strip: the strip shivers, nothing lands, and a ClashMark ticks in the board's corner tally.
3. Pick a cutting from a different volume and Paste — it lands, and the poem is now three strips tall.
4. Open Cuttings, type a quote by hand, set its page number, and attach it to a Volume; it enters the drawer as Fresh.
5. Open Volumes, tap Scan, hold the back of the book being given away until the ISBN latches, let the title and maker fill in, then mark the Volume Gone with a reason of Sold, Lent, Lost or Culled — its cuttings stay.
6. Peel lifts the newest strip off the board and returns that cutting to the drawer as Fresh.
7. Next morning the board is bare: yesterday's cento sealed at midnight and now hangs in the Gathering as a collage tile, and the strips it holds are Spent.

**Essential features**

- Cento board as home, drawn in CALayer: every strip is a CAShapeLayer with a torn cut-paper edge, its own paper tint, a slight seat angle and a soft paste shadow; the board scrolls as one canvas and the drawer rail sits under it.
- Cuttings drawer: hand-typed quote text plus page number and an attached Volume; a Cutting is Fresh, Pasted or Spent, and Spent cuttings sink to the bottom of the drawer and cannot be pasted again.
- Volumes sheet: create a Volume by typing, or by scanning its ISBN barcode before the book leaves; mark it Gone with a reason and a date, and its cuttings survive the volume — strips from a Gone Volume render with the title punched out of the paper.
- Adjacent-volume ban enforced by one pure predicate, with a ClashMark tally on the board and a full list of clashes in the Gathering.
- Midnight seal keyed by daykey: two or more strips seal the day's cento read-only; one strip or none writes Scrap and returns the strips to the drawer.
- Gathering: sealed centos as a paper-cut collage wall, plus counts of lines that outlived their book, volumes gone, longest cento and consecutive sealed days.
- Peel as a single-step undo on the board, and a plain-text copy of any sealed cento with its per-line volume attributions.
- Fully offline after the one ISBN lookup: no account, no sync, nothing leaves the device.

**Twist** — Adjacent-volume ban. Home is today's cento board. Paste lays the selected Cutting as a Strip at the foot of the board and the poem grows one line. A Cutting whose Volume equals the Volume of the Strip already at the foot is refused: the board writes a ClashMark, the strip shivers, and the foot keeps its line — another volume's cutting always remains pastable, so the button never dies. A Cutting that was pasted into a sealed Cento is Spent and cannot be pasted again. Peel lifts the newest Strip and returns its Cutting to the drawer as Fresh. At midnight a Cento holding two or more Strips seals with a SealMark and hangs in the Gathering; a Cento with one Strip or none writes Scrap and its strips go back to the drawer. Seed already pastes one Strip from a Gone Volume and stocks the drawer with cuttings from three other volumes, so the opening Paste can land. Home verb: paste-the-next-line — not mark-the-book's-fate and not browse-a-shelf.

**Why this is not a repeat** — Nothing in the portfolio composes. Margent, the only other gone-books app, makes home a shelf of slips where the verb records a volume's fate — sold, lost, returned — and the numbers are progress fractions; here the book's fate is a small field on a sheet and home is a composition canvas where the verb is assembling a daily cento out of lines whose books are gone. The unit of work is an ordering, not a record: a strip's value depends on what sits under it, which no app here has done, and the adjacent-volume ban is a constraint on sequence rather than on state, so the architecture is an append-only array plus a pure predicate instead of the enum folds that dominate the taken axis. Cresset and the reading boards measure pages; art_quiz drills a saved crate; catalog_crate rates a search result — none of them make the user write anything that is then rearranged. The ISBN scan is deliberately a farewell gesture, used once on a book that is leaving, not a browse loop, and every screen after that works with no network.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Shelf of spines. Drill shelf → book → margin.
- Invariant: One quote-store per book. Verdict is reread / not — no stars. progressFraction = currentPage/totalPages.
- Never: Not a store catalog crate.
- Desk `varroa_rate`: mites/100 bees; sugar factor 1.15; drop-board 2.4/days; month threshold. over iff raw≥threshold.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

### 3.1 Architecture contract

A Cento is an ordered array of CuttingIDs filed under its daykey and is never mutated in place: Paste appends one ID, Peel drops the tail, and Seal freezes the array and stamps every Cutting it references as Spent. Cutting and Volume live in two flat Codable side tables, so a quote's text is written exactly once and a Strip is only a rendered projection of a Cutting plus its seat index. The visible poem is derived at render by reducing the ID array through those side tables, which is why marking a Volume Gone, correcting a page number, or spending a Cutting reaches every board and every Gathering tile with no migration and no duplicated text. Legality is one pure predicate, canFollow(foot:next:), returning false when next.volumeID equals the foot Strip's volumeID and false when next.state is spent; the board, the drawer rail's enabled states, and the unit tests all call that same function. All mutation runs through CentoEngine, a value type that takes a StoreRoot and an intent and returns a new StoreRoot plus a Mark (clash, seal, or scrap), so no view controller ever edits a record directly. A Cento whose array is empty renders Blank, and midnight resolution is a pure function of daykey plus strip count, not of anything the UI holds.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

UIKit with manual CALayer drawing, canvas first. CentoBoardView owns one scrolling canvas layer inside a UIScrollView; each Strip is a CAShapeLayer whose path is a torn cut-paper rectangle with edge jitter seeded deterministically from the CuttingID, so a strip tears the same way every launch. Each strip carries its own paper tint from the fixed palette, a seat angle under one degree alternating by index, and a soft paste shadow via shadowPath so no offscreen rasterisation is needed; quote text draws into a CATextLayer inset from the torn edge, and a Gone Volume's title is punched out of the paper as an even-odd subpath rather than printed on it. The drawer rail sits under the canvas as a horizontal strip of small cutting tiles, each a layer-backed UIButton with contentShape over the whole tile and a 44pt minimum target, dimmed and non-tappable when canFollow says no. Layout is asymmetric-split: the canvas takes roughly eight columns of the width with the foot counter and ClashMark tally in the narrow four-column gutter on iPad and stacked as a sparse top rail on iPhone, and the board always fills remaining height rather than sitting in a centered column. Motion is quiet: a paste lands with a 180ms cross-fade and a two-point settle, the clash shiver is a 6pt damped nudge, counters tick with monospaced digits instead of sliding, and accessibilityReduceMotion swaps every one of those for an instant state change. Native UIKit controls everywhere off the canvas (UIButton, UISwitch, UITextView), VoiceOver labels on every icon-only control, and the board exposes each Strip as an accessibility element reading the quote, its volume, and its seat.

### 3.3 Naming contract

Convention: Cento / florilegium lexicon (Volume, Cutting, Strip, Cento, Drawer, Gathering, ClashMark, SealMark, Scrap).

Examples to follow: ['canFollow(foot:next:) -> Bool, the one legality predicate comparing volumeID and rejecting Spent', 'CentoBoardLayer / StripLayer, the canvas and the torn cut-paper strip that seats on it', "DrawerRail with Cutting.state of fresh, pasted, spent; Spent cuttings sink to the rail's tail", 'ClashMarkTally and SealMark, with Scrap for a day that closed holding fewer than two strips']

### 3.4 Dependency contract

Zero external dependencies. No Package.swift entry, no SPM remote, no CocoaPods, nothing vendored into the repo. The app links only Apple frameworks: UIKit and QuartzCore for the paste-up canvas, AVFoundation for the one ISBN capture session, Foundation and URLSession for the single frozen lookup, and XCTest for the target's tests. No analytics, no crash reporter, no networking wrapper; the lookup is a URLSession data task with a custom User-Agent and JSONDecoder. Everything after that one lookup runs offline with no account and no sync.

### 3.5 Navigation contract

Cento-locked chrome, and no tab bar at all. The paste-up board is the root view controller and never pushes; it is the only full screen the app has. A sparse top rail over the canvas holds four icon-only buttons (Cuttings, Volumes, Gathering, Settings), each a 44pt target with a VoiceOver label, and each presents a UISheetPresentationController over the board at a medium detent that the user can drag to large; the board stays visible and legible behind every sheet. Scan and search fuse inside Volumes: one field takes a typed ISBN and a Scan button opens the capture window in the same sheet, both feeding the same latch. Writing a cutting is a push inside the Cuttings sheet's own navigation controller, and marking a Volume Gone is a push inside the Volumes sheet; nothing escapes to the root stack. Onboarding is a full-page modal with the Continue button pinned bottom and full width, dismissed for good on first paste. ProcessInfo.processInfo.arguments is read once, after onboarding has been marked complete: -ReviewScreen today shows the seeded board, log opens the Cuttings drawer sheet, goals opens the Gathering, volumes opens the Volumes sheet, and settings opens Settings, each a different frame.

### 3.6 Screen composition contract

Cento, Cuttings, Volumes, Gathering, Settings

Cento board (root, full screen: scrolling paste-up canvas, foot counter and ClashMark tally in the narrow gutter, drawer rail under the canvas, Paste and Peel as the two wide bottom controls). Onboarding (full page, three quiet panels, Continue bottom full width). Cuttings sheet (drawer list grouped Fresh then Pasted then Spent, with a full-page empty state). Cutting editor (push inside Cuttings: quote text view, page number field, Volume picker, Save). Volumes sheet (list of volumes with typed or scanned entry, fused ISBN field and Scan button, full-page empty state). Volume scan (push inside Volumes: spine-shaped capture window, Simulator chips, manual ISBN entry). Volume detail (push inside Volumes: title, maker, its cuttings, and Mark Gone with reason Sold, Lent, Lost or Culled plus a date). Gathering sheet (paper-cut collage wall of sealed centos, the four counts, and a clash list; tapping a tile opens a sealed cento reader with per-line volume attributions and Copy). Settings sheet (contact URL, seal time note, delete-everything with a named confirm).

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By cento role (Cento, Strip, Cutting, Drawer, Volume, ClashMark, SealMark)**

```
Pastedown/
  Pastedown/
  App/ AppDelegate.swift, SceneDelegate.swift, ReviewScreenHook.swift, DemoSeed.swift, OnboardingViewController.swift
  Cento/ CentoBoardViewController.swift, CentoBoardView.swift, CentoBoardLayer.swift, CentoEngine.swift, Cento.swift, Daykey.swift, MidnightSeal.swift
  Strip/ Strip.swift, StripLayer.swift, TornEdgePath.swift, StripSeating.swift, PunchedTitleMask.swift
  Cutting/ Cutting.swift, CuttingEditorViewController.swift, CuttingState.swift
  Drawer/ DrawerRailView.swift, DrawerTileButton.swift, DrawerSheetViewController.swift, DrawerOrdering.swift
  Volume/ Volume.swift, VolumesSheetViewController.swift, VolumeDetailViewController.swift, VolumeScanViewController.swift, ISBN.swift, VolumeLookup.swift, GoneReason.swift
  Marks/ ClashMark.swift, SealMark.swift, Scrap.swift, MarkTallyView.swift
  Gathering/ GatheringViewController.swift, CollageWallLayer.swift, SealedCentoReaderViewController.swift, CentoPlainText.swift
  Settings/ SettingsViewController.swift
  Store/ StoreRoot.swift, CentoStore.swift, DebouncedWriter.swift, EmptyStateView.swift
  Design/ Palette.swift, TypeScale.swift, Space.swift, Radius.swift, Motion.swift, PaperTint.swift
  Resources/ Assets.xcassets, Info.plist
PastedownTests/
  CanFollowTests.swift, PasteAndPeelTests.swift, SealAndScrapTests.swift, DaykeyTests.swift, SpentCuttingTests.swift, StoreRoundTripTests.swift, ISBNChecksumTests.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Shelf
A first-class screen for **Shelf**. Must render empty, populated and error states.

### 5.3 Quotes
A first-class screen for **Quotes**. Must render empty, populated and error states.

### 5.4 Dashboard
A first-class screen for **Dashboard**. Must render empty, populated and error states.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Book** — named per this app's convention.
- **Quote** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **opencode-ai · asymmetric-split · branded**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#FFFFFF` | Screen background |
| `surface` | `#FFFFFF` | Cards, rows, sheets |
| `ink` | `#000000` | Primary text and icons |
| `accent` | `#CC7C00` | Primary action, key figure, progress fill |
| `muted` | `#6B6B6B` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro (system default) — strip text set in SF Pro Text at generous line spacing with optical kerning, the foot counter in SF Pro Display with monospaced digits, and no second face anywhere**

SF Pro only, no second face anywhere in the binary. Strip quote text is SF Pro Text at 17pt with line spacing set to roughly 1.45 of the point size and optical kerning on (kCTFontOpticalSizeAttribute left to the system, tracking untouched), so a three-line quote breathes inside its torn paper rather than filling it edge to edge; long quotes wrap to at most five lines on a strip before the strip grows taller. The foot counter, the ClashMark tally, the Gathering counts, and page numbers are SF Pro Display with monospacedDigit applied via UIFontDescriptor, so numbers tick in place without the layer reflowing. Volume titles and sheet headers are SF Pro Display semibold, short and wide, never more than two lines, and the punched-out title on a Gone Volume's strip uses the same face cut as a path so it reads as absence rather than as a second style. Body copy off the canvas stays at 17pt, captions are real sentences at 13pt, and all sizes come from TypeScale with ScaledMetric equivalents for the CATextLayer sizes so AX5 grows the strips instead of clipping them. Every number the user sees passes through NumberFormatter, and dates through Calendar.current.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **14pt** for cards, sheets and primary surfaces; **6pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **shadow** — a single soft drop-shadow token, reused everywhere a surface sits above another.

Primary control: **tinted glass** — primary chrome sits on a tinted translucent surface (`Material` plus the accent colour at low opacity), never plain flat colour.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **UIKit CALayer manual drawing · canvas-first**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **UIKit CALayer manual drawing · canvas-first** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **dark** (Dark-tech: void surfaces, one glow or jewel, sparse chrome.)

Reference system: **opencode-ai** — steal rhythm and restraint, not their colours or logos.

Mood: **AI coding platform. Developer-centric dark theme.**.

Home rhythm (`asymmetric-split`, comfortable): Uneven columns (7/5 or 8/4), not a clean 50/50.

Dark-tech: void surfaces, one glow or jewel, sparse chrome. Layout `asymmetric-split`, density comfortable. Kit 14/6, shadow, tinted glass. Palette recipe `branded`. Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Mono numerals, humanist body, no poster type. Reference type feel: dark.

Motion (`quiet`): Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap.

Voice (`editorial`): Complete sentences, no slang, no hype. Captions are real lines.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable — one Codable root under the key cento.store.v1 holding volumes, cuttings and centos as three flat arrays; centos store only CuttingIDs so a quote's text exists once; writes are debounced half a second**

One Codable root, StoreRoot, encoded with JSONEncoder and written to UserDefaults.standard under the single key cento.store.v1. The root holds three flat arrays: volumes, cuttings, and centos. A Cento stores only its daykey, its ordered [CuttingID] array, and its seal state, so a quote's text exists exactly once in cuttings and is never copied into a sealed record; the rendered poem is a reduce over the ID array at draw time. Writes are debounced half a second through DebouncedWriter, coalescing a burst of paste, peel, and edit into one encode, with an immediate flush on resignActive and on scene disconnect. Decode failures fall back to an empty root rather than crashing, and the version suffix in the key is the migration seam. The demo seed writes under pdn.demo.v1, guarded by targetEnvironment(simulator), and marks onboarding complete in the same pass so the review hook is reachable.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Pastedown/1.0 (iOS; +https://pastedown-cento.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.books`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_NSCameraUsageDescription: Scans the ISBN barcode on the back of a book so its title and publisher fill in before the book leaves your shelf.
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.books
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Adjacent-volume ban (a Cutting may not be pasted under a Strip from the same Volume; the ban writes a ClashMark and the foot keeps its line; a Cutting already pasted into a sealed Cento is Spent)

Paste lays the selected Cutting at the foot of today's board and the poem grows one line. If that Cutting's Volume equals the Volume of the Strip already at the foot, canFollow returns false: the board writes a ClashMark, the candidate strip shivers 6pt and does not land, the tally in the gutter ticks, and the foot keeps the line it had. The ban is on sequence, never on state, so a cutting refused at the foot becomes pastable the moment another volume's line sits under it, and the seed guarantees cuttings from three other volumes in the drawer so Paste is never dead. A Cutting that was pasted into a Cento that later sealed is Spent: it sinks to the tail of the drawer, renders dimmed with a struck rule, and canFollow refuses it for good. Peel is the single-step undo, lifting the newest Strip and returning its Cutting to the drawer as Fresh. At midnight, keyed by daykey, a Cento holding two or more Strips seals with a SealMark, goes read-only, stamps its cuttings Spent, and hangs in the Gathering as a collage tile; a Cento holding one Strip or none writes Scrap and returns its strips to the drawer as Fresh, and the new day's board opens Blank.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Paper cut origami collage · abstract**


Base prompt, reused and extended for every asset:

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here.
```

All 20 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `pdn_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `pdn_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `pdn_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `pdn_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `pdn_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `pdn_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `pdn_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `pdn_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `pdn_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `pdn_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `pdn_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Adjacent-volume ban (a Cutting may not be pasted under a Strip from the same Volume; the ban writes a ClashMark and the foot keeps its line; a Cutting already pasted into a sealed Cento is Spent)' feature screen. |
| 11 | `pdn_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `pdn_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |
| 13 | `pdn_EmptyBoardMark` | 1024x1024 | **required cutout** | Cutout with real PNG alpha: fully transparent corners and background, one solid paper-cut subject centred with no plate, no square backing and no frame. A single torn paper strip seen slightly from above, one long deckle edge and one clean cut edge, a soft crease running its length, floating with a faint contact shadow that also has alpha. Abstract, no text, no book. |
| 14 | `pdn_EmptyDrawerMark` | 1024x1024 | **required cutout** | Cutout with real PNG alpha: transparent corners and background, solid subject in the centre, no enclosing box or circle plate. A shallow open fold of paper, like a creased sleeve seen end on, empty inside, cut edges crisp and interior fully transparent only where the paper actually stops. Matte fibre, one contact shadow, abstract, no letterforms. |
| 15 | `pdn_EmptyVolumesMark` | 1024x1024 | **required cutout** | Cutout with real PNG alpha: transparent background and corners, one solid centred subject, no plate and no outline frame. Two flat paper rectangles leaning against each other at an angle, the front one shorter, both with knife-cut edges and one torn corner, forming an abstract pair rather than a depiction of books. Matte, soft stacking shadow, no spine text, no glyph. |
| 16 | `pdn_EmptyGatheringMark` | 1024x1024 | **required cutout** | Cutout with real PNG alpha: transparent corners, solid centred subject, no backing plate. A small cluster of four irregular paper shards arranged as an off-centre collage tile, overlapping at shallow angles with one shard punched through to nothing. Abstract, matte fibre, soft contact shadows, no type and no icon shape. |
| 17 | `pdn_SealMarkStamp` | 1024x1024 | **required cutout** | Cutout with real PNG alpha: transparent background, one solid centred subject, no plate, no ring frame. A pressed paper seal, an irregular torn disc with a deep crease folded across it and a raised ridge where the fold lifts, edges deckled. Abstract, no emblem, no letters, no numerals. Matte fibre, single soft shadow. |
| 18 | `pdn_ClashMarkGlyph` | 1024x1024 | **required cutout** | Cutout with real PNG alpha: transparent corners and background, solid subject centred, no plate. Two narrow paper strips laid across each other at a shallow angle, the upper one buckled as if it refused to lie flat, torn ends fraying. Small, legible at 20pt, abstract, no symbols and no text. Matte fibre with a thin contact shadow. |
| 19 | `pdn_ScrapMark` | 1024x1024 | **required cutout** | Cutout with real PNG alpha: transparent background, one solid centred subject, no frame or plate. A single short paper offcut, curled at one end, torn on three sides and cut clean on the fourth, lying at an angle. Abstract, matte fibre, faint contact shadow, no text. |
| 20 | `pdn_ShutterLeaf` | 1024x1024 | **required cutout** | Cutout with real PNG alpha used as the capture shutter that closes over the preview: two interlocking paper-cut leaves with clean knife edges and a torn inner lip, opaque across the leaf bodies and fully transparent outside them, sized to meet along a centre seam. Abstract, matte fibre, no aperture blades and no camera imagery, no text. |

### Prompt per asset

**`pdn_AppIcon`** — 1024x1024

```
Paper cut origami collage filling the full square canvas edge to edge, no margin and no rounded corner drawn in. Three torn paper strips stacked at slightly different seat angles into a small vertical column, the top strip narrower than the one beneath it, each with a fibrous torn edge and a thin contact shadow. Abstract, no letterforms, no book imagery. Asymmetric weight, one dominant strip, matte fibre surface. Reads clearly at 40pt.
```

**`pdn_Splash`** — 1290x2796

```
Paper cut origami collage filling the whole canvas, portrait, edge to edge with no border. A tall column of overlapping torn paper strips rising from the lower third, planes offset left and right so the column leans asymmetric, deep negative space above. Matte fibre texture, crisp knife-cut bevels against soft torn deckle, soft stacking shadows. Abstract only, no type, no glyphs.
```

**`pdn_Onboarding1`** — 1024x1536

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here., a person or object that is this product in one glance

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_Onboarding2`** — 1024x1536

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here., the primary action of this product, mid-gesture

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_Onboarding3`** — 1024x1536

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here., a later moment when the product has accumulated meaning

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_EmptyHome`** — 1024x1024

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here., a solid closed bowl, crate or folded cloth waiting to be used — ceramic, wood or fabric, fully opaque, not glass

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_EmptyList`** — 1024x1024

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here., an empty list, shelf or page

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_CardBackdrop`** — 1200x800

```
Paper cut origami collage filling the full rectangle, used behind a card. Wide horizontal bands of cut paper overlapping at shallow angles, one band punched clean through to the layer below, weight pushed to one side so the opposite third stays quiet enough for type to sit on. Matte, fibrous, low contrast within the composition, no focal glyph.
```

**`pdn_ControlFace`** — 512x512

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here., the face of a single physical control such as a dial, key or slider handle

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_TwistHero`** — 1024x1024

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here., an emblem representing this app's signature feature

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_SuccessMark`** — 512x512

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here., a confirmation mark or celebratory emblem

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_HeaderDecor`** — 1200x600

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here., a wide decorative band or ornament

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_EmptyBoardMark`** — 1024x1024

```
Cutout with real PNG alpha: fully transparent corners and background, one solid paper-cut subject centred with no plate, no square backing and no frame. A single torn paper strip seen slightly from above, one long deckle edge and one clean cut edge, a soft crease running its length, floating with a faint contact shadow that also has alpha. Abstract, no text, no book.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_EmptyDrawerMark`** — 1024x1024

```
Cutout with real PNG alpha: transparent corners and background, solid subject in the centre, no enclosing box or circle plate. A shallow open fold of paper, like a creased sleeve seen end on, empty inside, cut edges crisp and interior fully transparent only where the paper actually stops. Matte fibre, one contact shadow, abstract, no letterforms.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_EmptyVolumesMark`** — 1024x1024

```
Cutout with real PNG alpha: transparent background and corners, one solid centred subject, no plate and no outline frame. Two flat paper rectangles leaning against each other at an angle, the front one shorter, both with knife-cut edges and one torn corner, forming an abstract pair rather than a depiction of books. Matte, soft stacking shadow, no spine text, no glyph.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_EmptyGatheringMark`** — 1024x1024

```
Cutout with real PNG alpha: transparent corners, solid centred subject, no backing plate. A small cluster of four irregular paper shards arranged as an off-centre collage tile, overlapping at shallow angles with one shard punched through to nothing. Abstract, matte fibre, soft contact shadows, no type and no icon shape.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_SealMarkStamp`** — 1024x1024

```
Cutout with real PNG alpha: transparent background, one solid centred subject, no plate, no ring frame. A pressed paper seal, an irregular torn disc with a deep crease folded across it and a raised ridge where the fold lifts, edges deckled. Abstract, no emblem, no letters, no numerals. Matte fibre, single soft shadow.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_ClashMarkGlyph`** — 1024x1024

```
Cutout with real PNG alpha: transparent corners and background, solid subject centred, no plate. Two narrow paper strips laid across each other at a shallow angle, the upper one buckled as if it refused to lie flat, torn ends fraying. Small, legible at 20pt, abstract, no symbols and no text. Matte fibre with a thin contact shadow.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_ScrapMark`** — 1024x1024

```
Cutout with real PNG alpha: transparent background, one solid centred subject, no frame or plate. A single short paper offcut, curled at one end, torn on three sides and cut clean on the fourth, lying at an angle. Abstract, matte fibre, faint contact shadow, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`pdn_ShutterLeaf`** — 1024x1024

```
Cutout with real PNG alpha used as the capture shutter that closes over the preview: two interlocking paper-cut leaves with clean knife edges and a torn inner lip, opaque across the leaf bodies and fully transparent outside them, sized to meet along a centre seam. Abstract, matte fibre, no aperture blades and no camera imagery, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`pdn.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `PastedownTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Pastedown -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Append-only paste-up (a Cento is an ordered array of CuttingIDs and is never mutated in place; Cutting and Volume are flat Codable records held in two side tables; the poem is derived by reduce at render, so a strip's text is stored once; legality is one pure predicate canFollow(foot, next) comparing volumeID; Paste appends, Peel drops the tail, Seal freezes the array under its daykey and stamps its cuttings Spent; a board with no strips renders Blank)** with no leakage across layers.
- [ ] UI approach matches **UIKit CALayer manual drawing · canvas-first**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Cento-locked chrome (the paste-up board never leaves home; Cuttings, Volumes, Gathering and Settings arrive as sheets over it; scan and search fuse inside Volumes)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro (system default) — strip text set in SF Pro Text at generous line spacing with optical kerning, the foot counter in SF Pro Display with monospaced digits, and no second face anywhere** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Pastedown
xcodegen generate
xcodebuild -scheme Pastedown -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Pastedown -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
