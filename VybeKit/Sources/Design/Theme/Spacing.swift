import CoreGraphics

public extension Theme {
    /// Gaps and padding, in points. For spacing that should grow with text, wrap in `@ScaledMetric`.
    enum Spacing {
        public static let tiny: CGFloat = 4
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
        public static let extraLarge: CGFloat = 24
        public static let huge: CGFloat = 32
    }

    /// Corner radii, in points.
    enum Radius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 20
        /// Photo-first cards: soft, generous corners (use with `.continuous`).
        public static let extraLarge: CGFloat = 28
    }

    /// Fixed sizes that are not gaps or radii.
    enum Size {
        /// Smallest tap target (AGENTS.md 5a).
        public static let minTapTarget: CGFloat = 44

        /// Widest a block of reading text may grow. `nil` means no limit.
        /// PENDING DESIGN DECISION: the team has not chosen a number, so none is invented here.
        public static let readableContentMaxWidth: CGFloat? = nil
    }
}
