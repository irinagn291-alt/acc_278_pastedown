import Foundation

/// Role: Volume. Domain result of one ISBN latch. Mapped from a DTO, never decoded from the wire.
struct VolumeLatch: Equatable, Codable, Sendable {
    var isbn: String
    var title: String
    var maker: String
    var pageCount: Int?
}
