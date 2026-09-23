import XCTest
@testable import Pastedown

final class DaykeyTests: XCTestCase {
    func test_startOfDayIsStableInUTC() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let morning = Date(timeIntervalSince1970: 1_746_000_000)
        let afternoon = morning.addingTimeInterval(60 * 60 * 8)
        XCTAssertEqual(Daykey.of(morning, calendar: calendar), Daykey.of(afternoon, calendar: calendar))
        XCTAssertEqual(Daykey.of(morning, calendar: calendar).yyyymmdd, 20250430)
    }

    func test_previousCrossesMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let first = Daykey(yyyymmdd: 20260501)
        XCTAssertEqual(first.previous(calendar: calendar)?.yyyymmdd, 20260430)
    }

    func test_shortDaylightSavingDayStillHasOneKey() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 3
        parts.day = 8
        parts.hour = 1
        let early = calendar.date(from: parts) ?? Date()
        parts.hour = 4
        let late = calendar.date(from: parts) ?? Date()
        XCTAssertEqual(Daykey.of(early, calendar: calendar), Daykey.of(late, calendar: calendar))
    }
}
