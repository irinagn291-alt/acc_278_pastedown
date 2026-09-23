import Foundation

/// Role: Gathering. Plain-text copy of a sealed cento with per-line volume attributions.
enum CentoPlainText: Sendable {
    static func render(cento: Cento, root: StoreRoot) -> String {
        let strips = Strip.poem(from: cento, root: root)
        return strips.map { strip in
            let page = CentoFigures.page(strip.page)
            let title = strip.volumeTitle.isEmpty ? "Volume" : strip.volumeTitle
            return "\(strip.text)\n\(title), page \(page)"
        }.joined(separator: "\n\n")
    }
}

/// Role: Gathering. Every visible number goes through NumberFormatter.
enum CentoFigures: Sendable {
    static func page(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func count(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func counted(_ value: Int, singular: String, plural: String) -> String {
        "\(count(value)) \(value == 1 ? singular : plural)"
    }
}
