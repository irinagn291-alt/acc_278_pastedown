import Foundation

/// Role: Gathering. Derived counts. Never stored. Outlived lines are boarded or sealed cuttings whose volume is gone.
struct GatheringTally: Equatable, Sendable {
    var outlivedLineCount: Int
    var goneVolumeCount: Int
    var longestCento: Int
    var consecutiveSealedDays: Int

    static func from(_ root: StoreRoot, today: Daykey, calendar: Calendar) -> GatheringTally {
        let sealed = root.centos.filter { $0.seal == .sealed }
        let todayIDs = root.cento(on: today)?.cuttingIDs ?? []
        let visibleIDs = Set(sealed.flatMap(\.cuttingIDs) + todayIDs)
        let visible = visibleIDs.compactMap { root.cutting($0) }
        let goneIDs = Set(root.volumes.filter(\.isGone).map(\.id))
        let outlived = visible.filter { goneIDs.contains($0.volumeID) }
        let longest = sealed.map(\.cuttingIDs.count).max() ?? 0
        return GatheringTally(
            outlivedLineCount: outlived.count,
            goneVolumeCount: Set(outlived.map(\.volumeID)).count,
            longestCento: longest,
            consecutiveSealedDays: consecutiveSealedDays(
                centos: root.centos,
                today: today,
                calendar: calendar
            )
        )
    }

    private static func consecutiveSealedDays(
        centos: [Cento],
        today: Daykey,
        calendar: Calendar
    ) -> Int {
        let sealed = Set(centos.filter { $0.seal == .sealed }.map(\.daykey))
        let start: Daykey
        if sealed.contains(today) {
            start = today
        } else if let yesterday = today.previous(calendar: calendar) {
            start = yesterday
        } else {
            return 0
        }
        var count = 0
        var cursor = start
        while sealed.contains(cursor) {
            count += 1
            guard let prior = cursor.previous(calendar: calendar) else { break }
            cursor = prior
        }
        return count
    }

    static func week(
        ending today: Daykey,
        centos: [Cento],
        calendar: Calendar
    ) -> [SealedDayMark] {
        let sealed = Set(centos.filter { $0.seal == .sealed }.map(\.daykey))
        let weekday = DateFormatter()
        weekday.calendar = calendar
        weekday.locale = .current
        weekday.setLocalizedDateFormatFromTemplate("EEE")
        let number = DateFormatter()
        number.calendar = calendar
        number.locale = .current
        number.setLocalizedDateFormatFromTemplate("d")
        var keys: [Daykey] = [today]
        var cursor = today
        for _ in 1..<7 {
            guard let prior = cursor.previous(calendar: calendar) else { break }
            keys.append(prior)
            cursor = prior
        }
        return keys.reversed().map { key in
            let date = key.date(calendar: calendar)
            let isSealed = sealed.contains(key)
            let isToday = key == today
            let status: String
            if isSealed {
                status = "Sealed"
            } else if isToday {
                status = "Open"
            } else {
                status = "No seal"
            }
            return SealedDayMark(
                daykey: key,
                weekday: date.map { weekday.string(from: $0) } ?? CentoFigures.count(key.yyyymmdd),
                dayNumber: date.map { number.string(from: $0) } ?? "",
                status: status,
                isSealed: isSealed
            )
        }
    }
}

struct SealedDayMark: Equatable, Sendable {
    var daykey: Daykey
    var weekday: String
    var dayNumber: String
    var status: String
    var isSealed: Bool
}
