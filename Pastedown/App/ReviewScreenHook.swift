import Foundation

/// Role: App. Parses `-ReviewScreen` once after onboarding. Keys are launch arguments, not tabs.
enum ReviewScreenHook: Sendable {
    enum Destination: String, Equatable, Sendable {
        case today
        case log
        case goals
        case cento
        case cuttings
        case gathering
        case volumes
        case sold
        case lent
        case lost
        case settings
    }

    /// Reads the first `-ReviewScreen` value. Unknown slugs return nil and fall through to home.
    static func destination(from arguments: [String]) -> Destination? {
        guard let flag = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: flag)
        guard next < arguments.endIndex else { return nil }
        return Destination(rawValue: arguments[next])
    }

    /// Reads ProcessInfo once after onboarding; required live-shot hook.
    static func destinationFromProcessInfo() -> Destination? {
        destination(from: ProcessInfo.processInfo.arguments)
    }
}
