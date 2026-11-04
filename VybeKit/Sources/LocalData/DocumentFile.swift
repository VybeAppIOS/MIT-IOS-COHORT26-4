import Core
import Foundation
import Models

/// What is written to disk: the data plus the format version (ADR 004).
struct Document<Value: Codable & Sendable>: Codable, Sendable {
    var schemaVersion: Int
    var value: Value
}

private struct Header: Decodable {
    let schemaVersion: Int
}

public enum DocumentFileError: Error, Equatable {
    /// The file was written by a newer app version. It is left untouched so nothing is lost.
    case newerVersion(found: Int, supported: Int)
}

/// One JSON file in Application Support with ONE serial writer (ADR 005): being an `actor`, calls run one at a time,
/// so ten quick saves are ten whole, atomic writes in order and the file is always valid.
/// A file that cannot be read is never deleted: it is renamed `<name>.corrupt-<timestamp>.json`, logged (no personal
/// data) and the app starts empty.
public actor DocumentFile<Value: Codable & Sendable> {
    public static var supportedSchemaVersion: Int { 1 }

    private let url: URL
    private let empty: Value
    private let now: @Sendable () -> Date
    private var quarantined = false

    public init(url: URL, empty: Value, now: @escaping @Sendable () -> Date = { Date() }) {
        self.url = url
        self.empty = empty
        self.now = now
    }

    public func load() throws -> Value {
        guard FileManager.default.fileExists(atPath: url.path) else { return empty }
        do {
            let data = try Data(contentsOf: url)
            // Check the version before reading the body: a newer file may have a different shape, and that must
            // never look like a corrupt file.
            let found = try JSONCoding.decoder.decode(Header.self, from: data).schemaVersion
            guard found <= Self.supportedSchemaVersion else {
                throw DocumentFileError.newerVersion(found: found, supported: Self.supportedSchemaVersion)
            }
            return try JSONCoding.decoder.decode(Document<Value>.self, from: data).value
        } catch let error as DocumentFileError {
            throw error
        } catch {
            quarantine()
            return empty
        }
    }

    /// Writes the whole value atomically (a crash mid-write leaves the old file).
    public func save(_ value: Value) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONCoding.encoder.encode(Document(schemaVersion: Self.supportedSchemaVersion, value: value))
        try data.write(to: url, options: .atomic)
    }

    /// True once after a file was set aside, so the app can show a one-time notice.
    public func takeQuarantineNotice() -> Bool {
        defer { quarantined = false }
        return quarantined
    }

    private func quarantine() {
        let stamp = Int(now().timeIntervalSince1970)
        let name = url.deletingPathExtension().lastPathComponent
        let target = url.deletingLastPathComponent().appending(path: "\(name).corrupt-\(stamp).json")
        do {
            try FileManager.default.moveItem(at: url, to: target)
            quarantined = true
            Log.data.error("A data file could not be read and was moved aside.")
        } catch {
            Log.data.error("A data file could not be read and could not be moved aside.")
        }
    }
}

/// `library.json`: Saved, Drafts, runs and their owner-only times.
public typealias LibraryFile = DocumentFile<Library>

/// Where the app keeps its own files.
public enum LocalDataPaths {
    public static var directory: URL { URL.applicationSupportDirectory.appending(path: "Vybe") }
    public static var libraryURL: URL { directory.appending(path: "library.json") }
    public static var profileURL: URL { directory.appending(path: "profile.json") }
}
