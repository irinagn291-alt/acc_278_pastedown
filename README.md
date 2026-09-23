# Pastedown

Keep quotes from books you no longer own and paste one a day into a growing poem.

Pastedown is for library borrowers, book-swappers, and people who cull their shelves. A reader pastes a kept quote onto today's cento board so the line outlives the book it came from. Everything stays on this device. There is no account and no sync.

## Why an append-only paste-up

A cento is an ordered array of CuttingIDs filed under a daykey. It is never mutated in place. Paste appends one ID. Peel drops the tail. Seal freezes the array and stamps every cutting it references as Spent.

Cutting and Volume live in two flat Codable side tables, so a quote's text is written exactly once. A Strip is only a rendered projection of a Cutting plus its seat index. The visible poem is derived at render by reducing the ID array through those tables. Marking a Volume Gone, correcting a page number, or spending a Cutting reaches every board and every Gathering tile with no duplicated text.

Legality is one pure predicate, `canFollow(foot:next:)`. It returns false when the next cutting shares the foot strip's volumeID, and false when the next cutting is Spent. The board, the drawer rail, and the unit tests all call that same function.

All mutation runs through `CentoEngine`, a value type that takes a `StoreRoot` and an intent and returns a new root plus an optional Mark. View controllers never edit a record directly.

This product is an ordering, not a shelf of records. A strip's value depends on what sits under it. An append-only array plus a pure predicate is the right shape for that.

## Adjacent-volume ban

A cutting may not be pasted under a strip from the same volume. The ban writes a ClashMark, the foot strip shivers, and the foot keeps its line. Another volume's cutting is always pastable, so Paste never dies. A cutting that was pasted into a sealed cento is Spent and cannot be pasted again.

Peel lifts the newest strip and returns that cutting to the drawer as Fresh. At midnight, a cento holding two or more strips seals and hangs in the Gathering. A cento with one strip or none writes Scrap and returns its strips to the drawer.

That sequence constraint is why someone would pick this app over a gone-books shelf whose home verb is recording a volume's fate.

## Art

Style: paper cut origami collage, abstract.

Base prompt reused for every asset:

```
Paper cut origami collage, abstract. Torn and knife-cut paper laid in overlapping planes with visible deckle fibre on the torn edges and a clean bevel on the cut ones, each plane sitting a millimetre above the one below with a soft contact shadow so depth reads as stacking rather than as gradient. Shapes are abstract strips, wedges and folded creases, never letterforms, never book illustrations, never a quill or an open book. Composition is asymmetric, weighted off-centre, with one dominant plane and smaller shards answering it; negative space is punched clean through, not painted over. Matte fibrous surface, no gloss, no photographic texture overlay, no gradient mesh, no drop shadow on text. Quiet and editorial, handmade but precise, as if trimmed with a scalpel on a cutting mat. Colours come from the fixed palette and are not specified here.
```

Image sets (prefix `pdn_`): AppIcon, Splash, Onboarding1, Onboarding2, Onboarding3, EmptyHome, EmptyList, CardBackdrop, ControlFace, TwistHero, SuccessMark, HeaderDecor, EmptyBoardMark, EmptyDrawerMark, EmptyVolumesMark, EmptyGatheringMark, SealMarkStamp, ClashMarkGlyph, ScrapMark, ShutterLeaf.

Exact per-asset prompts live in SPEC.md section 13.2. Assets are generated in a later step. The imagesets are named and empty until then.

## How this is not a repeat

Nothing in the nearby portfolio composes. Margent makes home a shelf of slips whose verb records a volume's fate. Here the book's fate is a small field on a sheet. Home is a composition canvas whose verb is assembling a daily cento. Cresset and the reading boards measure pages. This app writes an ordering that can be peeled and sealed.

## Build

```bash
cd apps/Pastedown
xcodegen generate
xcodebuild -scheme Pastedown -destination 'generic/platform=iOS Simulator' build-for-testing
```

iOS 17, Swift 6.2, zero package dependencies. UIKit and QuartzCore draw the board. AVFoundation captures one ISBN. URLSession does one frozen Open Library lookup. After that the app is offline.

Review screenshots use launch arguments, not tabs:

`-ReviewScreen today` the board, `log` Cuttings, `goals` Gathering, `volumes` Volumes, `settings` Settings.
