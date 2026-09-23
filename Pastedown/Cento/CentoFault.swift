import Foundation

/// Role: Cento. Typed failures for engine intents. Views never parse strings for these.
enum CentoFault: Error, Equatable, Sendable {
    case unknownVolume
    case unknownCutting
    case emptyQuote
    case pageOutOfRange
    case missingTitle
    case centoSealed
    case alreadyGone
    case spentCutting
    case cancelled
    case notFound
    case decoding
    case transport
}
