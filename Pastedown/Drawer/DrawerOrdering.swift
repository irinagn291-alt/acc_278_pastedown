import Foundation

/// Role: Drawer. Spent cuttings sink to the tail. Fresh, then pasted, then spent.
enum DrawerOrdering: Sendable {
    static func ordered(_ cuttings: [Cutting]) -> [Cutting] {
        let rank: [CuttingState: Int] = [
            .fresh: 0,
            .pasted: 1,
            .spent: 2,
        ]
        return cuttings.enumerated().sorted { lhs, rhs in
            let left = rank[lhs.element.state] ?? 0
            let right = rank[rhs.element.state] ?? 0
            if left != right { return left < right }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }
}
