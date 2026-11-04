import SwiftUI

public extension Theme {
    /// Animation timings, exactly as `docs/MOTION.md` section 2.
    enum Motion {
        public static let quick = Animation.snappy(duration: 0.25)
        public static let standard = Animation.smooth(duration: 0.35)
        public static let gentle = Animation.smooth(duration: 0.6)
        public static let playful = Animation.spring(duration: 0.45, bounce: 0.3)
        public static let fade = Animation.easeInOut(duration: 0.2)

        /// With Reduce Motion on, every token becomes a plain fade.
        public static func resolve(_ animation: Animation, reduceMotion: Bool) -> Animation {
            reduceMotion ? fade : animation
        }
    }
}
