import Foundation

/// Role: Cutting. Fresh sits in the drawer, pasted sits on an open cento, spent is sealed away.
enum CuttingState: String, Codable, Equatable, Sendable {
    case fresh
    case pasted
    case spent
}
