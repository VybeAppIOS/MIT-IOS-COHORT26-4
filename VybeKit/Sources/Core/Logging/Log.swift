import os

/// One logger per area. Never `print`, and never personal data in a log line (`AGENTS.md` 5a).
public enum Log {
    private static let subsystem = "com.lohitaksh.Vybe"

    public static let app = Logger(subsystem: subsystem, category: "App")
    public static let data = Logger(subsystem: subsystem, category: "Data")
    public static let navigation = Logger(subsystem: subsystem, category: "Navigation")
    public static let onboarding = Logger(subsystem: subsystem, category: "Onboarding")
    public static let discover = Logger(subsystem: subsystem, category: "Discover")
    public static let hangout = Logger(subsystem: subsystem, category: "Hangout")
    public static let live = Logger(subsystem: subsystem, category: "Live")
    public static let search = Logger(subsystem: subsystem, category: "Search")
    public static let profile = Logger(subsystem: subsystem, category: "Profile")
    public static let community = Logger(subsystem: subsystem, category: "Community")
    public static let chat = Logger(subsystem: subsystem, category: "Chat")
    public static let safety = Logger(subsystem: subsystem, category: "Safety")
}
