import Foundation
import Models

/// Everything team-made that ships inside the app: Places and Hangouts.
public struct ContentSnapshot: Sendable {
    public var places: [Place]
    public var hangouts: [Hangout]

    public init(places: [Place] = [], hangouts: [Hangout] = []) {
        self.places = places
        self.hangouts = hangouts
    }
}

/// Why a content file could not be used. Always names the file, so a bad file is easy to find.
public enum ContentError: Error, Equatable, CustomStringConvertible {
    case folderMissing(String)
    case missingSchemaVersion(file: String)
    /// The file was written by a newer major version of the data format than this app understands.
    case unsupportedSchema(file: String, found: Int, supported: Int)
    case invalidFile(file: String, reason: String)

    public var description: String {
        switch self {
        case .folderMissing(let path): "Content folder not found: \(path)"
        case .missingSchemaVersion(let file): "\(file): no schemaVersion"
        case .unsupportedSchema(let file, let found, let supported):
            "\(file): schemaVersion \(found) is newer than this app understands (\(supported)). Update the app."
        case .invalidFile(let file, let reason): "\(file): \(reason)"
        }
    }
}

/// Reads `Places/*.json` and `Hangouts/*.json` from a content folder (ADR 004). All JSON goes through `JSONCoding`.
public struct ContentLoader: Sendable {
    /// The data format major version this app reads. Older files are accepted; newer ones are rejected.
    public static let supportedSchemaVersion = 1

    public let contentDirectory: URL

    public init(contentDirectory: URL) {
        self.contentDirectory = contentDirectory
    }

    /// The content bundled in the app (`Resources/Content`).
    public static var bundled: ContentLoader {
        ContentLoader(contentDirectory: Bundle.module.url(forResource: "Content", withExtension: nil)
            ?? Bundle.module.resourceURL!.appending(path: "Content"))
    }

    /// The folder photos are read from (`Content/Photos`).
    public var photosDirectory: URL { contentDirectory.appending(path: "Photos") }

    public func load() throws -> ContentSnapshot {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: contentDirectory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw ContentError.folderMissing(contentDirectory.path)
        }
        return ContentSnapshot(
            places: try decodeAll(Place.self, folder: "Places"),
            hangouts: try decodeAll(Hangout.self, folder: "Hangouts"))
    }

    private struct Header: Decodable { let schemaVersion: Int? }

    private func decodeAll<T: Decodable>(_ type: T.Type, folder: String) throws -> [T] {
        let directory = contentDirectory.appending(path: folder)
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return try files.map { try decode(type, from: $0) }
    }

    private func decode<T: Decodable>(_ type: T.Type, from file: URL) throws -> T {
        let name = file.lastPathComponent
        do {
            let data = try Data(contentsOf: file)
            guard let version = try JSONCoding.decoder.decode(Header.self, from: data).schemaVersion else {
                throw ContentError.missingSchemaVersion(file: name)
            }
            guard version <= Self.supportedSchemaVersion else {
                throw ContentError.unsupportedSchema(file: name, found: version, supported: Self.supportedSchemaVersion)
            }
            return try JSONCoding.decoder.decode(type, from: data)
        } catch let error as ContentError {
            throw error
        } catch {
            throw ContentError.invalidFile(file: name, reason: String(describing: error))
        }
    }
}

/// Loads the content once and shares it with every repository. A failed load is not cached, so the next call retries.
public actor ContentStore {
    private let loader: ContentLoader
    private var cached: ContentSnapshot?

    public init(loader: ContentLoader) {
        self.loader = loader
    }

    public var photosDirectory: URL { loader.photosDirectory }

    public func snapshot() throws -> ContentSnapshot {
        if let cached { return cached }
        let loaded = try loader.load()
        cached = loaded
        return loaded
    }
}
