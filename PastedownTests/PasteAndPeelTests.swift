import XCTest
@testable import Pastedown

final class PasteAndPeelTests: XCTestCase {
    private var calendar: Calendar!
    private var now: Date!
    private var engine: CentoEngine!

    override func setUp() {
        calendar = Self.utcCalendar()
        now = Date(timeIntervalSince1970: 1_746_000_000)
        engine = CentoEngine(calendar: calendar)
    }

    func test_pasteEmptyPopulatedAndInvalid() throws {
        var root = StoreRoot.empty
        let gone = Volume(
            id: DemoSeed.paperHoursID,
            title: "Paper Hours",
            maker: "North Binding",
            currentPage: 42,
            totalPages: 216
        )
        let other = Volume(
            id: DemoSeed.lentSpineID,
            title: "The Lent Spine",
            maker: "Harbor Press",
            currentPage: 18,
            totalPages: 180
        )
        root = try engine.apply(.addVolume(gone), to: root).root
        root = try engine.apply(.addVolume(other), to: root).root

        do {
            _ = try engine.apply(
                .addCutting(Cutting(volumeID: gone.id, text: "   ", page: 3)),
                to: root
            )
            XCTFail("expected emptyQuote")
        } catch {
            XCTAssertEqual(error as? CentoFault, .emptyQuote)
        }

        do {
            _ = try engine.apply(
                .addCutting(Cutting(volumeID: gone.id, text: "A line.", page: 0)),
                to: root
            )
            XCTFail("expected pageOutOfRange")
        } catch {
            XCTAssertEqual(error as? CentoFault, .pageOutOfRange)
        }

        do {
            _ = try engine.apply(.paste(CuttingID(), at: now), to: root)
            XCTFail("expected unknownCutting")
        } catch {
            XCTAssertEqual(error as? CentoFault, .unknownCutting)
        }

        root = try engine.apply(
            .addCutting(
                Cutting(
                    id: DemoSeed.boardCuttingID,
                    volumeID: gone.id,
                    text: "The line outlives the binding that first held it.",
                    page: 42
                )
            ),
            to: root
        ).root
        root = try engine.apply(
            .addCutting(
                Cutting(
                    id: DemoSeed.drawerLentID,
                    volumeID: other.id,
                    text: "Keep the sentence. The shelf can go.",
                    page: 18
                )
            ),
            to: root
        ).root

        let first = try engine.apply(.paste(DemoSeed.boardCuttingID, at: now), to: root)
        XCTAssertNil(first.mark)
        XCTAssertEqual(first.root.cento(on: Daykey.of(now, calendar: calendar))?.cuttingIDs, [
            DemoSeed.boardCuttingID,
        ])
        XCTAssertEqual(first.root.cutting(DemoSeed.boardCuttingID)?.state, .pasted)

        let second = try engine.apply(.paste(DemoSeed.drawerLentID, at: now), to: first.root)
        XCTAssertNil(second.mark)
        XCTAssertEqual(second.root.cento(on: Daykey.of(now, calendar: calendar))?.cuttingIDs, [
            DemoSeed.boardCuttingID,
            DemoSeed.drawerLentID,
        ])
        let poem = Strip.poem(
            from: try XCTUnwrap(second.root.cento(on: Daykey.of(now, calendar: calendar))),
            root: second.root
        )
        XCTAssertEqual(poem.map(\.text), [
            "The line outlives the binding that first held it.",
            "Keep the sentence. The shelf can go.",
        ])
    }

    func test_pasteSameVolumeWritesClashAndKeepsFoot() throws {
        var root = DemoSeed.root(now: now, calendar: calendar)
        let extra = Cutting(
            id: CuttingID(),
            volumeID: DemoSeed.culledMarginID,
            text: "Another line from the same volume.",
            page: 50
        )
        root = try engine.apply(.addCutting(extra), to: root).root
        let before = try XCTUnwrap(root.cento(on: Daykey.of(now, calendar: calendar)))
        let outcome = try engine.apply(.paste(extra.id, at: now), to: root)
        guard case .clash(let clash) = outcome.mark else {
            return XCTFail("expected clash")
        }
        XCTAssertEqual(clash.refusedID, extra.id)
        XCTAssertEqual(clash.footID, DemoSeed.drawerCulledID)
        XCTAssertEqual(
            outcome.root.cento(on: Daykey.of(now, calendar: calendar))?.cuttingIDs,
            before.cuttingIDs
        )
        XCTAssertEqual(outcome.root.cutting(extra.id)?.state, .fresh)
        XCTAssertEqual(outcome.root.clashMarks.count, 1)
    }

    func test_peelDropsTailAndReturnsFresh() throws {
        var root = DemoSeed.root(now: now, calendar: calendar)
        let afterPaste = try XCTUnwrap(root.cento(on: Daykey.of(now, calendar: calendar)))
        XCTAssertEqual(afterPaste.cuttingIDs, [
            DemoSeed.boardCuttingID,
            DemoSeed.drawerLentID,
            DemoSeed.drawerCulledID,
        ])
        let peeled = try engine.apply(.peel(at: now), to: root)
        XCTAssertEqual(
            peeled.root.cento(on: Daykey.of(now, calendar: calendar))?.cuttingIDs,
            [DemoSeed.boardCuttingID, DemoSeed.drawerLentID]
        )
        XCTAssertEqual(peeled.root.cutting(DemoSeed.drawerCulledID)?.state, .fresh)
        XCTAssertEqual(afterPaste.cuttingIDs.count, 3)
    }

    func test_centoIsAppendOnlyAndTextLivesOnce() throws {
        let root = DemoSeed.root(now: now, calendar: calendar)
        let before = try XCTUnwrap(root.cento(on: Daykey.of(now, calendar: calendar)))
        let beforeIDs = before.cuttingIDs
        let outcome = try engine.apply(.paste(DemoSeed.drawerSoldID, at: now), to: root)
        let after = try XCTUnwrap(outcome.root.cento(on: Daykey.of(now, calendar: calendar)))
        XCTAssertEqual(beforeIDs, [
            DemoSeed.boardCuttingID,
            DemoSeed.drawerLentID,
            DemoSeed.drawerCulledID,
        ])
        XCTAssertEqual(after.cuttingIDs, beforeIDs + [DemoSeed.drawerSoldID])
        let labels = Mirror(reflecting: after).children.compactMap(\.label)
        XCTAssertFalse(labels.contains { $0.localizedCaseInsensitiveContains("text") })
        XCTAssertFalse(labels.contains { $0.localizedCaseInsensitiveContains("quote") })
        XCTAssertEqual(
            outcome.root.cutting(DemoSeed.drawerSoldID)?.text,
            "Tomorrow the board is bare. Today it still takes a paste."
        )
    }

    func test_peelOnBlankIsNoOp() throws {
        let day = Daykey.of(now, calendar: calendar)
        var root = StoreRoot.empty
        root.upsert(Cento(daykey: day))
        let outcome = try engine.apply(.peel(at: now), to: root)
        XCTAssertTrue(outcome.root.cento(on: day)?.isBlank ?? false)
        XCTAssertNil(outcome.mark)
    }

    func test_typedVolumeWithoutISBN_acceptsRealPagesAndRaisesTotalPages() throws {
        var root = StoreRoot.empty
        let typed = Volume(
            title: "Typed volume",
            maker: "Manual entry",
            currentPage: 0,
            totalPages: 1
        )
        root = try engine.apply(.addVolume(typed), to: root).root
        let first = Cutting(
            volumeID: typed.id,
            text: "A page deep in the book.",
            page: 42
        )
        root = try engine.apply(.addCutting(first), to: root).root
        XCTAssertEqual(root.volume(typed.id)?.totalPages, 42)

        let second = Cutting(
            volumeID: typed.id,
            text: "A much later page still lands.",
            page: 180
        )
        let next = try engine.apply(.addCutting(second), to: root)
        XCTAssertEqual(next.root.volume(typed.id)?.totalPages, 180)
        XCTAssertEqual(next.root.cutting(second.id)?.page, 180)
    }

    func test_isbnVolumeKeepsUpperPageBound() throws {
        var root = StoreRoot.empty
        let catalogued = Volume(
            title: "Catalogued volume",
            maker: "North Binding",
            isbn: "9780306406157",
            currentPage: 0,
            totalPages: 100
        )
        root = try engine.apply(.addVolume(catalogued), to: root).root
        XCTAssertThrowsError(
            try engine.apply(
                .addCutting(Cutting(volumeID: catalogued.id, text: "Out of range.", page: 101)),
                to: root
            )
        ) { error in
            XCTAssertEqual(error as? CentoFault, .pageOutOfRange)
        }
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
