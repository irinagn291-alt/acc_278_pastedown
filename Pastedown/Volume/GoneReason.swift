import Foundation

/// Role: Volume. Why a volume left the shelf. Cuttings survive the mark.
enum GoneReason: String, Codable, Equatable, Sendable, CaseIterable {
    case sold
    case lent
    case lost
    case culled
}

/// Role: Volume. Gone stamp. Date is the day the volume left, not a reading score.
struct GoneMark: Equatable, Codable, Sendable {
    var reason: GoneReason
    var date: Date
}
