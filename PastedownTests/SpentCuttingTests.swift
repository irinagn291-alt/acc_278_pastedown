import XCTest
@testable import Pastedown

final class SpentCuttingTests: XCTestCase {
    private var calendar: Calendar!
    private var engine: CentoEngine!

    override func setUp() {
        calendar = Self.utcCalendar()
        engine = CentoEngine(calendar: calendar)
    }

    func test_spentCuttingCannotPasteAndSinksInDrawer() throws {
        let yesterday = Date(timeIntervalSince1970: 1_745_913_600)
        let today = Date(timeIntervalSince1970: 1_746_000_000)
        var root = DemoSeed.root(now: yesterday, calendar: calendar)
        root = try engine.apply(.resolveMidnight(at: today), to: root).root

        do {
            _ = try engine.apply(.paste(DemoSeed.drawerLentID, at: today), to: root)
            XCTFail("expected spentCutting")
        } catch {
            XCTAssertEqual(error as? CentoFault, .spentCutting)
        }

        let ordered = DrawerOrdering.ordered(root.cuttings)
        XCTAssertEqual(ordered.last?.state, .spent)
        XCTAssertTrue(ordered.drop(while: { $0.state != .spent }).allSatisfy { $0.state == .spent })
        XCTAssertEqual(root.cutting(DemoSeed.drawerSoldID)?.state, .fresh)
        XCTAssertTrue(
            ordered.firstIndex(where: { $0.id == DemoSeed.drawerSoldID })!
                < ordered.firstIndex(where: { $0.id == DemoSeed.drawerLentID })!
        )
    }

    func test_pasteOnSealedCentoFails() throws {
        let yesterday = Date(timeIntervalSince1970: 1_745_913_600)
        let today = Date(timeIntervalSince1970: 1_746_000_000)
        var root = DemoSeed.root(now: yesterday, calendar: calendar)
        root = try engine.apply(.resolveMidnight(at: today), to: root).root
        var sealed = try XCTUnwrap(root.cento(on: Daykey.of(yesterday, calendar: calendar)))
        sealed = sealed.freezing(as: .sealed)
        root.upsert(sealed)
        do {
            _ = try engine.apply(.paste(DemoSeed.drawerSoldID, at: yesterday), to: root)
            XCTFail("expected centoSealed")
        } catch {
            XCTAssertEqual(error as? CentoFault, .centoSealed)
        }
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
