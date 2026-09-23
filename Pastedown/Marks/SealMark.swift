import Foundation

/// Role: SealMark. A day that closed with two or more strips and hangs in the Gathering.
struct SealMark: Equatable, Codable, Sendable {
    var daykey: Daykey
    var stripCount: Int
}
