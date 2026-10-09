<!-- gf-brief source=14a696ac742a40a37378f806e5edb4958c737a0cc968e266a101a307a3dd5079 written=2026-09-30T09:06:12+03:00 -->
# Pastedown

## What it is

Pastedown is a private cento board for people who keep lines from books they sell, lend, lose, or cull. You write a cutting (a quote plus its page and volume), paste it onto today's board as the next strip, and peel the last strip if you change your mind. Neighbours on the board cannot come from the same volume. The sentence is meant to stay on this device after the book leaves.

## Launch and onboarding

A cold launch can sit on a blank screen for a few seconds. A small spinner may appear with no caption. iOS may also ask whether the app can send notifications (system wording; there is no custom usage string).

The home board then fills the screen. On a first launch that has no saved work, three full-screen pages appear over it. Pages can be swiped. Page dots sit above the bottom button. **Skip** is always at the top trailing corner. **Continue** is always at the bottom.

1. **Keep the line after the book leaves.**  
   **Pastedown holds quotes from volumes you sell, lend, lose, or cull. The sentence stays on this device.**
2. **Paste the next line onto today's board.**  
   **Pick a cutting in the drawer and tap Paste. The quote lands as a strip at the foot of the cento.**
3. **Two neighbours cannot share a volume.**  
   **A cutting from the same book as the foot will not land. The clash tally counts each refusal, and another volume is always pastable.**

**Continue** on pages 1 and 2 advances. **Continue** on page 3, or **Skip** on any page, dismisses the pages and leaves you on today's board. The pages do not return on later launches unless you ask for them in Settings.

On an iPhone Simulator that has never been wiped, the opening pages are skipped and sample books and lines are already on the board. On a device with no saved work, the board is empty under the pages.

There is no custom launch caption. Appearance is Light only.

## Screens

There is no tab bar. Four icon buttons sit on the home board. **Cuttings**, **Volumes**, **Sealed**, and **Settings** open sheets over the board. **Volumes**, **Settings**, and **Adjacent volume ban** (when opened from the board) have no **Close** control; drag the sheet down. **Cuttings** and **Sealed centos** have **Close**.

### Today's board

Headline: **Build today's cento**  
Line: **Select a cutting in the drawer, then tap Paste to add the next line.**

A banner may appear:

- **The last save was recovered from a backup copy.**
- **The store could not be read, so the board started empty.**
- **Paste could not be stored.**
- **Peel could not be stored.**
- **That volume is not on the shelf.**
- **That cutting is not in the drawer.**
- **Write the line before you save it.**
- **The page needs to sit inside the volume.**
- **A volume needs a title.**
- **Today's cento is already sealed.**
- **This volume is already marked gone.**
- **A spent cutting cannot be pasted again.**
- **The lookup was cancelled.**
- **The catalogue has no record for that ISBN.**
- **The catalogue reply could not be read.**
- **The lookup could not reach the catalogue.**

Top icon buttons:

- **Cuttings** — opens the **Cuttings** sheet.
- **Volumes** — opens the **Volumes** sheet.
- **Sealed** (VoiceOver: **Sealed centos**) — opens **Sealed centos**.
- **Settings** — opens **Settings**.

When today's cento has no strips:

- **No lines on today's cento yet.**
- If there are no cuttings: **Write a cutting, then paste it as the first line.** and **Open Cuttings** (opens **Cuttings**).
- If cuttings already exist: **Pick a cutting in the drawer, then tap Paste to add the next line.** (no extra button).

When strips exist:

- Card title **Cento so far**, then the pasted lines stacked as text.
- Each strip also shows the quote and **{volume title}, page {page}** (or **Volume** if the title is missing).
- Slot card: **Next line lands here** / **Select a cutting in the drawer, then tap Paste.**

Tally (above the board on iPhone; beside it on a regular-width iPad):

- **Lines on the board**
- A count, then **line pasted onto today's cento** or **lines pasted onto today's cento**
- Control **Same-volume pastes refused**
  - Count **0**: **None refused yet. Open clash marks**
  - Otherwise: **{n} refused paste** or **{n} refused pastes**. **Open clash marks**
  - Tap opens **Adjacent volume ban**
- On regular width only, a **Clash marks** list. Empty: **No same-volume pastes have been refused yet. Paste from another volume to add the next line.** Rows show the refused line and a medium-style date.

Drawer rail: chips of cuttings that are not already on today's board. Each chip shows the quote and the volume title. VoiceOver adds **page {page}** and **Fresh**, **Pasted**, or **Spent**. Spent quotes are struck through. Same-volume-as-the-last-line and **Spent** chips are dimmed and cannot be chosen. The chosen chip is highlighted. **All cuttings** opens **Cuttings**.

Bottom:

- **Paste** — pastes the chosen cutting, or the first legal cutting if none is chosen. A successful paste can flash a mark with no caption. A same-volume attempt does not add a strip; VoiceOver says **Same volume. The foot keeps its line.** and the clash count rises.
- **Peel** — lifts the last strip. That cutting returns to **Fresh** and comes back in the rail.

### Cuttings

Title: **Cuttings**  
**Close** (VoiceOver: **Close cuttings**) dismisses the sheet. A plus control (VoiceOver: **Write a cutting**) starts a new cutting, or an alert if there is no volume yet.

Empty drawer:

- **The drawer is empty.**
- **Write a quote, set its page, and attach it to a volume. It enters as Fresh.**
- **Write a cutting**

Sections appear only when they have rows: **Fresh**, **Pasted**, **Spent**. A row shows the quote and **{volume title}, page {page}. Reread.** or **… Not reread.** **Spent** rows are muted. Tap a row to open **Edit cutting**.

**Sources** lists each volume as **{n} cutting** / **cuttings** and **{n} reread** / **rereads**. Those rows do not open anything. If there are no volumes:

- **No volumes yet.**
- **A cutting needs a volume before it can enter the drawer.**

Footer on **Sources**: **Reread cuttings stay in the drawer so you can paste a line you already lived with.** then **{n} cutting is marked reread.** or **{n} cuttings are marked reread.**

Alert when writing with no volume:

- Title: **Add a volume first**
- **A cutting needs a volume before it can enter the drawer.**
- **Open Volumes** — only dismisses **Cuttings** and returns to the board. It does not open **Volumes**.
- **Cancel**

### Write a cutting / Edit cutting

Title: **Write a cutting** (new) or **Edit cutting** (existing).

- Quote field (no placeholder).
- **Page number** and field placeholder **Page**
- **Volume** and a picker of volume titles
- **Reread** and a switch (off for a new cutting)
- **Save** — stores the cutting and returns to **Cuttings**. Leaving without **Save** discards the draft.

Inline errors:

- **Write the line before you save it.**
- **The page needs to be a whole number.**
- **The page needs to sit inside the volume.**
- **That volume is not on the shelf.**
- **The cutting could not be stored.**

### Volumes

Title: **Volumes**

Always-visible form:

- **ISBN**
- **Scan** — pushes **Scan**
- **Title**
- **Maker**
- **Total pages**
- Status line (as needed):
  - **Looking up ISBN...**
  - **Title and maker filled from the catalogue.**
  - **Title and maker filled from the scan.**
  - catalogue faults plus ** Type the title yourself, or try again.**
  - **The lookup failed. Type the title yourself, or try again.**
  - **A volume needs a title.**
  - **Total pages needs to be a whole number.**
  - **The volume could not be stored.**
- **Add volume** — adds the book and clears the fields.

Empty shelf (also shows with the form):

- **The shelf is empty.**
- **Type a title or scan an ISBN before the book leaves. Its cuttings stay even after it is gone.**
- **Scan an ISBN** — opens **Scan**

A volume row shows the title and **{maker}. {progress percent}. Still here.** or **Gone, Sold.** / **Gone, Lent.** / **Gone, Lost.** / **Gone, Culled.** Tap opens that volume. A blank **Maker** still prints the period before the percent.

### Volume detail

Navigation title is the volume title.

- **Total pages**
- **Save total pages**
- Segments: **Sold**, **Lent**, **Lost**, **Culled**
- A date control
- **Mark gone** — confirm first
- While still on the shelf: **Marking it gone keeps every cutting. The book's fate is a field, not the home verb.**
- After it is gone: **Marked sold on {date}. Cuttings stay.** (or **lent** / **lost** / **culled**). **Mark gone** is dimmed and does nothing.
- Section header: **{maker}. Playhead {percent}.**
- Empty cuttings: **No cuttings yet.** / **Write one in the drawer and attach it here.**
- A cutting row: quote and **Page {n}. Reread.** or **Page {n}. Not reread.** Tap opens **Edit cutting**.

**Mark gone** alert:

- **Mark {title} as sold?** (or **lent** / **lost** / **culled**)
- **Its cuttings stay on the board and in the drawer.**
- **Cancel** / **Mark gone**

Other errors: **Total pages needs to be a whole number.** / **Total pages cannot sit below the current page.** / **The gone mark could not be stored.** / **The page count could not be stored.** plus the shared catalogue/board lines when they apply.

### Scan

Title: **Scan**  
Field: **ISBN**  
Buttons (shown only when needed): **Continue**, **Open Settings**, **Try again**

A tall spine-shaped window sits above the field. Status lines:

- Device, not yet asked: **Hold the back of the book so the ISBN can fill the title.** **Continue** presents the system camera alert.
- Camera running: **Hold the back of the book until the ISBN latches.**
- Denied or restricted: **The scanner cannot see the barcode because camera access is off. Open Settings to turn it on.** **Open Settings**
- No camera: **This device has no camera. Type the ISBN instead.**
- Camera failed: **The camera could not start. Type the ISBN instead.**
- Simulator: **Simulator has no camera. Use a sample ISBN or type one.** **Continue** is hidden. Chips: **Paper Hours**, **Sample two**, **Sample three**
- **Looking up ISBN...**
- **{title} is ready to add.** then the screen pops back to **Volumes**
- catalogue faults plus ** Type the title on the previous screen.** and **Try again**
- **The lookup failed. Type the title on the previous screen.**

The system camera alert is the only place that says Allow. The usage string is **Scans the ISBN barcode on the back of a book so its title and publisher fill in before the book leaves your shelf.**

### Sealed centos

Title: **Sealed centos**  
**Close** (VoiceOver: **Close sealed centos**) and **Back to the board** both dismiss to today's board.

Intro: **Read the sealed-day streak, then open a cento or return to today's board.**

- **Consecutive sealed days** — **No consecutive sealed days yet** or **{n} day** / **{n} days**
- Seven day chips: localized weekday, day number, and **Sealed**, **Open** (today if not sealed), or **No seal**
- **Longest sealed cento** — **No sealed cento yet** or **{n} line** / **{n} lines**
- **Lines that outlived their volume** — **None yet** or **{n} line** / **{n} lines**
- **Gone volumes on those lines** — **None yet** or **{n} volume** / **{n} volumes**

Wall heading **Sealed centos**. Each card: medium-style date, **{n} sealed line** / **{n} sealed lines**, then each strip and **{title}, page {page}**. Tap opens the reader for that day.

Empty wall:

- **No day has sealed yet.**
- **A day with two or more strips seals at midnight and hangs here.**

**Clash marks** — empty: **No clashes yet.** / **A same-volume paste writes a mark and keeps the foot.** (not tappable). With marks: refused line plus date; tap pushes **Adjacent volume ban**.

### Sealed cento reader

Title is that day's medium-style date. **Copy** copies the cento as plain text (quote, then **{title}, page {page}**, blank line between strips). There is no on-screen confirmation.

Empty (should not appear for a hanging sealed day):

- **This cento has no strips.**
- **A scrap day does not hang here.**

A line from a gone volume adds ** Title punched from the paper.** after the page.

### Adjacent volume ban

Title: **Adjacent volume ban**

- **A cutting may not sit under its own volume.**
- **Paste writes a ClashMark and the foot keeps its line. Another volume is always pastable, so Paste never dies. A cutting sealed into a cento is Spent and cannot be pasted again.**

Section **Clash marks**. Empty row: **The list is empty.** / **A same-volume paste will write the first mark.** Footer empty: **No refusals yet. The seed leaves Paste able to land from another volume.** Footer with marks: **Each mark is persisted with the store. The tally on the board is this list counted.** Rows are not tappable.

### Settings

Title: **Settings**

**Store**

- **Nothing stored yet.** or **The store has work on it.**
- **A failed write never leaves the board showing a line that is not saved.** or **The last write failed. Try again after you paste or peel.**
- Footer empty: **The store is empty. Write a volume or a cutting when you are ready.**
- Footer with work: **Volumes {n}, cuttings {n}.**
- Same recovery lines as the board banner when they apply.

**Midnight seal**

- **Seal time**
- **Keyed by the civil day, not by a clock the UI holds.**
- Footer: **At midnight the board seals if it holds two or more strips. A thinner day writes Scrap and returns the lines to the drawer.**

**This device**

- **Show the opening pages again** — dismisses Settings and replays the three opening pages.
- **Delete everything** / **Removes every volume, cutting, cento and clash mark.**

**Contact**

- **Contact**
- A website address under the title. Tap opens the support page.

**Delete everything?** / **This removes every volume, cutting, cento and clash mark from this device. It cannot be undone.** / **Keep** / **Delete everything**  
If wipe fails: **Delete failed** / **The store could not be wiped. Try again.** / **OK**

## Features

- Hold quotes from volumes you sell, lend, lose, or cull
- Today's cento board
- Paste the next line as a strip at the foot
- Peel the last strip
- Drawer of cuttings in **Fresh**, **Pasted**, and **Spent**
- Write or edit a cutting (quote, page, volume, **Reread**)
- Shelf of volumes (title, maker, ISBN, total pages)
- Scan or type an ISBN so title and maker can fill from the catalogue
- Mark a volume gone as **Sold**, **Lent**, **Lost**, or **Culled** without dropping its cuttings
- Adjacent-volume ban (two neighbours cannot share a volume)
- Clash marks and a clash tally
- Midnight seal of a day with two or more strips
- Scrap of a thinner day (lines return to the drawer)
- Sealed-day streak and sealed centos wall
- Copy a sealed cento
- Lines that outlived their volume / gone volumes on those lines
- Playhead progress on a volume
- Replay the opening pages
- Delete everything on this device
- Contact

## Behaviours that can look like bugs

- **Paste** stays dim until there is a cutting that can follow the last line (a different volume, not **Spent**). On a first empty day, add a volume, write a cutting, then **Paste**.
- After a successful **Paste**, the last line often remains the selection. **Paste** can stay enabled if another volume could land, but tapping **Paste** again refuses, leaves the board unchanged, and adds a clash. Tap a chip from another volume first.
- Cuttings from the same volume as the last line, and **Spent** cuttings, are dimmed and cannot be chosen. That is the ban, not a freeze.
- Cuttings already on today's board leave the rail. They remain in **Cuttings**.
- **Peel** stays dim while the board is empty or after that day has sealed. Paste at least one line first.
- **Open Cuttings** is the way out of a first empty board. **Write a cutting** then **Add a volume first**. **Open Volumes** only closes **Cuttings**; tap **Volumes** on the board yourself.
- **Add volume** needs a **Title**. **Maker**, **ISBN**, and **Total pages** can be blank. Blank pages become one page. A typed ISBN that is not a valid ISBN-10 or ISBN-13 does not look up and shows no extra error.
- **Save** on a cutting needs a non-empty quote and a whole page number of at least 1. A volume that already has an ISBN also requires the page to sit inside **Total pages**. Empty or out-of-range page: **The page needs to sit inside the volume.**
- **Save** and **Add volume** dim while a save is in flight, then return.
- After midnight (the civil day), a board with two or more strips is gone from home and hangs under **Sealed**. A day with one strip or none does not hang; that line returns to the drawer as **Fresh**. Today's board starts empty. There is no extra alert.
- **Mark gone** does nothing once the volume is already gone.
- Camera off: **Scan** shows **Open Settings** and will not preview until camera is on in Settings.
- Simulator **Scan** has no camera; use a sample chip or type an ISBN.
- **Volumes**, **Settings**, and the board's clash sheet have no **Close**; drag them down.
- **Copy** on a sealed cento gives no on-screen toast.
- After **Delete everything**, the board is empty in that session. The next cold launch on a device shows the opening pages again.

## Starter content and resume

On a device: none. You start with an empty shelf, an empty drawer, and an empty board.

On the iPhone Simulator (until **Delete everything**), sample work is already there and the opening pages are skipped:

Volumes: **Paper Hours** (North Binding, gone sold), **The Lent Spine** (Harbor Press), **Culled Margin** (Kiln & Quire), **Sold Light** (Deckled House).

Cuttings: **A sold volume still leaves the line that outlived it.**; **The shelf can forget. The cento keeps the sentence.**; **The line outlives the binding that first held it.**; **Keep the sentence. The shelf can go.**; **I cut the page I needed and let the rest travel on.**; **A borrowed copy still leaves a mark in the hand.**; **Tomorrow the board is bare. Today it still takes a paste.**; **Two lines from one volume cannot sit together.**

Today's board already has three strips. Yesterday already has a sealed two-line cento. One clash mark already exists for **Two lines from one volume cannot sit together.**

Today's open cento, the drawer, the shelf, clash marks, and sealed days come back after you leave the app, until midnight seals or scraps that day. A cutting or volume you have not saved is not kept. **Peel** can undo today's last paste until the day seals.

## Permissions

**Notifications.** Asked on first launch (system alert). No custom usage string.

**Camera.** Asked only on **Scan**, after **Continue**, if access is still undecided. Usage string: **Scans the ISBN barcode on the back of a book so its title and publisher fill in before the book leaves your shelf.** Denied or restricted: **Open Settings**. Not asked for microphone, photos, location, or tracking.

## Absent

Genuinely absent: login or accounts; in-app purchase; ads; analytics screens or an App Tracking Transparency prompt; public user-generated content (quotes stay private on this device; **Copy** only writes to the pasteboard); an account deletion flow (there is no account). **Delete everything** wipes local work only.

## Data and support

Onboarding states **The sentence stays on this device.** **Delete everything** states that volumes, cuttings, centos, and clash marks are removed **from this device**. Looking up an ISBN can fill title and maker from a catalogue; that is the only catalogue hop in the native UI.

**Settings** → **Contact** opens the support page.

## Scanning and health

The app scans the ISBN barcode on the back of a book (ISBN-10 or ISBN-13). You can also type the ISBN. A scanned code that contains those digits, including a QR code that holds them, is accepted. It is not a general QR reader and it does not expect product-health or medical codes.

Health, medical, or product-health information: None. No citations.

## Platform

UI copy is English. Dates and numbers follow the device locale. There is no in-app region switch and no region lock in the build settings. Portrait only, on iPhone and iPad. iPad is full screen. Light appearance only. Minimum iOS 17.0.

## Category

Books
