import XCTest
@testable import Pastedown

final class SealAndScrapTests: XCTestCase {
    private var calendar: Calendar!
    private var engine: CentoEngine!

    override func setUp() {
        calendar = Self.utcCalendar()
        engine = CentoEngine(calendar: calendar)
    }

    func test_twoStripsSealAndStampSpent() throws {
        let yesterday = Date(timeIntervalSince1970: 1_745_913_600)
        let today = Date(timeIntervalSince1970: 1_746_000_000)
        var root = DemoSeed.root(now: yesterday, calendar: calendar)
        let outcome = try engine.apply(.resolveMidnight(at: today), to: root)
        guard case .seal(let seal) = outcome.mark else {
            return XCTFail("expected seal")
        }
        let prior = Daykey.of(yesterday, calendar: calendar)
        XCTAssertEqual(seal.daykey, prior)
        XCTAssertEqual(seal.stripCount, 3)
        XCTAssertEqual(outcome.root.cento(on: prior)?.seal, .sealed)
        XCTAssertEqual(outcome.root.cutting(DemoSeed.boardCuttingID)?.state, .spent)
        XCTAssertEqual(outcome.root.cutting(DemoSeed.drawerLentID)?.state, .spent)
        XCTAssertTrue(outcome.root.cento(on: Daykey.of(today, calendar: calendar))?.isBlank ?? false)
        XCTAssertFalse(
            CentoEngine.canFollow(
                foot: nil,
                next: try XCTUnwrap(outcome.root.cutting(DemoSeed.boardCuttingID))
            )
        )
    }

    func test_oneStripWritesScrapAndReturnsFresh() throws {
        let yesterday = Date(timeIntervalSince1970: 1_745_913_600)
        let today = Date(timeIntervalSince1970: 1_746_000_000)
        var root = StoreRoot.empty
        root.upsert(
            Volume(
                id: DemoSeed.paperHoursID,
                title: "Paper Hours",
                maker: "North Binding",
                currentPage: 42,
                totalPages: 216
            )
        )
        root.upsert(
            Cutting(
                id: DemoSeed.boardCuttingID,
                volumeID: DemoSeed.paperHoursID,
                text: "The line outlives the binding that first held it.",
                page: 42,
                state: .pasted
            )
        )
        root.upsert(Cento(daykey: Daykey.of(yesterday, calendar: calendar), cuttingIDs: [DemoSeed.boardCuttingID]))
        let outcome = try engine.apply(.resolveMidnight(at: today), to: root)
        guard case .scrap(let scrap) = outcome.mark else {
            return XCTFail("expected scrap")
        }
        XCTAssertEqual(scrap.returnedIDs, [DemoSeed.boardCuttingID])
        XCTAssertEqual(outcome.root.cento(on: Daykey.of(yesterday, calendar: calendar))?.seal, .scrap)
        XCTAssertEqual(outcome.root.cutting(DemoSeed.boardCuttingID)?.state, .fresh)
    }

    func test_midnightVerdictIsPureStripCount() {
        XCTAssertEqual(MidnightSeal.verdict(stripCount: 0), .scrap)
        XCTAssertEqual(MidnightSeal.verdict(stripCount: 1), .scrap)
        XCTAssertEqual(MidnightSeal.verdict(stripCount: 2), .sealed)
        XCTAssertEqual(MidnightSeal.verdict(stripCount: 5), .sealed)
    }

    func test_gatheringTallyCountsSealedDays() throws {
        let today = Date(timeIntervalSince1970: 1_746_000_000)
        let root = DemoSeed.root(now: today, calendar: calendar)
        let tally = GatheringTally.from(
            root,
            today: Daykey.of(today, calendar: calendar),
            calendar: calendar
        )
        XCTAssertEqual(tally.goneVolumeCount, 1)
        XCTAssertEqual(tally.longestCento, 2)
        XCTAssertEqual(tally.consecutiveSealedDays, 1)
        XCTAssertEqual(tally.outlivedLineCount, 2)
        let week = GatheringTally.week(
            ending: Daykey.of(today, calendar: calendar),
            centos: root.centos,
            calendar: calendar
        )
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(week.last?.status, "Open")
        XCTAssertEqual(week.dropLast().last?.isSealed, true)
        XCTAssertEqual(week.dropLast().last?.status, "Sealed")
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
