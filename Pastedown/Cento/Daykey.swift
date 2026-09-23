import Foundation

/// Role: Cento. Civil day identity from Calendar.startOfDay. Midnight seal keys on this, not the UI clock.
struct Daykey: Hashable, Codable, Sendable, Comparable {
    var yyyymmdd: Int

    init(yyyymmdd: Int) {
        self.yyyymmdd = yyyymmdd
    }

    static func of(_ date: Date, calendar: Calendar) -> Daykey {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return Daykey(yyyymmdd: year * 10_000 + month * 100 + day)
    }

    func date(calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = yyyymmdd / 10_000
        parts.month = (yyyymmdd / 100) % 100
        parts.day = yyyymmdd % 100
        return calendar.date(from: parts).map { calendar.startOfDay(for: $0) }
    }

    func previous(calendar: Calendar) -> Daykey? {
        guard let day = date(calendar: calendar) else { return nil }
        guard let prior = calendar.date(byAdding: .day, value: -1, to: day) else { return nil }
        return Daykey.of(prior, calendar: calendar)
    }

    static func < (lhs: Daykey, rhs: Daykey) -> Bool {
        lhs.yyyymmdd < rhs.yyyymmdd
    }
}
