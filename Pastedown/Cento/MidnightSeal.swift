import Foundation

/// Role: Cento. Pure midnight verdict from strip count. Two or more seal. One or none scrap.
enum MidnightSeal: Sendable {
    static func verdict(stripCount: Int) -> CentoSeal {
        stripCount >= 2 ? .sealed : .scrap
    }
}
