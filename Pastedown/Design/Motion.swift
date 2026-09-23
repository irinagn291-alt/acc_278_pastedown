import QuartzCore
import UIKit

/// Role: Design. Quiet motion. Cross-fade 180 ms ease-out. Numbers tick. Reduce Motion is instant.
enum Motion {
    static let duration: TimeInterval = 0.18
    static let settlePoints: CGFloat = 2
    static let shiverPoints: CGFloat = 6

    static var reduce: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    static func fade(_ layer: CALayer, to opacity: Float) {
        layer.removeAnimation(forKey: "pdn.fade")
        if reduce {
            layer.opacity = opacity
            return
        }
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        anim.fromValue = layer.presentation()?.opacity ?? layer.opacity
        anim.toValue = opacity
        layer.add(anim, forKey: "pdn.fade")
        layer.opacity = opacity
    }

    static func settle(_ layer: CALayer) {
        layer.removeAnimation(forKey: "pdn.settle")
        if reduce { return }
        let anim = CABasicAnimation(keyPath: "transform.translation.y")
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        anim.fromValue = settlePoints
        anim.toValue = 0
        layer.add(anim, forKey: "pdn.settle")
    }

    static func shiver(_ layer: CALayer) {
        layer.removeAnimation(forKey: "pdn.shiver")
        if reduce { return }
        let anim = CASpringAnimation(keyPath: "transform.translation.x")
        anim.fromValue = shiverPoints
        anim.toValue = 0
        anim.damping = 14
        anim.stiffness = 220
        anim.mass = 1
        anim.duration = duration
        layer.add(anim, forKey: "pdn.shiver")
    }
}
