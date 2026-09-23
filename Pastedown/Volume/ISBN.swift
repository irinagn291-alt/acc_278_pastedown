import Foundation

/// Role: Volume. Normalised ISBN-10 or ISBN-13 with checksum. Scan extract is 8 to 14 digit runs.
struct ISBN: Hashable, Sendable {
    var canonical: String

    static func parse(_ raw: String) -> ISBN? {
        let compact = compactForm(raw)
        if compact.count == 13, compact.allSatisfy(\.isNumber), checksum13(compact) {
            return ISBN(canonical: compact)
        }
        if compact.count == 10, checksum10(compact) {
            return ISBN(canonical: compact)
        }
        if compact.count == 12, compact.allSatisfy(\.isNumber) {
            return parse("0" + compact)
        }
        return nil
    }

    /// Camera / QR helper: take the longest valid 8...14 digit run, with UPC-A pad.
    static func extract(from raw: String) -> ISBN? {
        let pattern = try? NSRegularExpression(pattern: "[0-9]{8,14}X?", options: [.caseInsensitive])
        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        let matches = pattern?.matches(in: raw, options: [], range: range) ?? []
        let runs = matches.compactMap { match -> String? in
            guard let slice = Range(match.range, in: raw) else { return nil }
            return String(raw[slice])
        }.sorted { $0.count > $1.count }
        for run in runs {
            if let isbn = parse(run) { return isbn }
        }
        return parse(raw)
    }

    private static func compactForm(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var scalars: [Character] = []
        for character in trimmed.uppercased() where character.isNumber || character == "X" {
            scalars.append(character)
        }
        return String(scalars)
    }

    private static func checksum13(_ digits: String) -> Bool {
        let values = digits.compactMap { $0.wholeNumberValue }
        guard values.count == 13 else { return false }
        var sum = 0
        for (index, value) in values.enumerated() {
            sum += value * (index.isMultiple(of: 2) ? 1 : 3)
        }
        return sum.isMultiple(of: 10)
    }

    private static func checksum10(_ compact: String) -> Bool {
        let characters = Array(compact)
        guard characters.count == 10 else { return false }
        var sum = 0
        for (index, character) in characters.enumerated() {
            let weight = 10 - index
            if character == "X" {
                guard index == 9 else { return false }
                sum += 10 * weight
            } else if let value = character.wholeNumberValue {
                sum += value * weight
            } else {
                return false
            }
        }
        return sum.isMultiple(of: 11)
    }
}
