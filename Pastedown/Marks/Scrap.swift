import Foundation

/// Role: Scrap. A day that closed holding fewer than two strips. Those cuttings return Fresh.
struct Scrap: Equatable, Codable, Sendable {
    var daykey: Daykey
    var returnedIDs: [CuttingID]
}
