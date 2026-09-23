import CoreGraphics
import UIKit

/// Role: Strip. Deterministic torn cut-paper path. The same CuttingID tears the same way every launch.
enum TornEdgePath {
    static func make(in rect: CGRect, seed: CuttingID) -> UIBezierPath {
        var rng = PaperRNG(uuid: seed.rawValue)
        let path = UIBezierPath()
        let step: CGFloat = 8
        let jitter: CGFloat = 3.5

        func j() -> CGFloat {
            (rng.next() - 0.5) * 2 * jitter
        }

        path.move(to: CGPoint(x: rect.minX + j(), y: rect.minY + j()))
        var x = rect.minX
        while x < rect.maxX {
            x = min(x + step, rect.maxX)
            path.addLine(to: CGPoint(x: x + j() * 0.3, y: rect.minY + j()))
        }
        var y = rect.minY
        while y < rect.maxY {
            y = min(y + step, rect.maxY)
            path.addLine(to: CGPoint(x: rect.maxX + j(), y: y + j() * 0.3))
        }
        x = rect.maxX
        while x > rect.minX {
            x = max(x - step, rect.minX)
            path.addLine(to: CGPoint(x: x + j() * 0.3, y: rect.maxY + j()))
        }
        y = rect.maxY
        while y > rect.minY {
            y = max(y - step, rect.minY)
            path.addLine(to: CGPoint(x: rect.minX + j(), y: y + j() * 0.3))
        }
        path.close()
        return path
    }
}

private struct PaperRNG {
    private var state: UInt64

    init(uuid: UUID) {
        let bytes = uuid.uuid
        let a = UInt64(bytes.0) << 56
            | UInt64(bytes.1) << 48
            | UInt64(bytes.2) << 40
            | UInt64(bytes.3) << 32
            | UInt64(bytes.4) << 24
            | UInt64(bytes.5) << 16
            | UInt64(bytes.6) << 8
            | UInt64(bytes.7)
        let b = UInt64(bytes.8) << 56
            | UInt64(bytes.9) << 48
            | UInt64(bytes.10) << 40
            | UInt64(bytes.11) << 32
            | UInt64(bytes.12) << 24
            | UInt64(bytes.13) << 16
            | UInt64(bytes.14) << 8
            | UInt64(bytes.15)
        state = a ^ b
        if state == 0 { state = 0x9E37_79B9_7F4A_7C15 }
    }

    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        let unit = Double(state >> 11) / Double(1 << 53)
        return CGFloat(unit)
    }
}
