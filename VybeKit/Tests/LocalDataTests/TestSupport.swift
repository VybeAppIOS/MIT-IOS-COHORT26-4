import Foundation
import LocalData

/// Shared helpers for the LocalData tests. Fixtures are EXAMPLE files, not real places.
enum TestSupport {
    static var fixtures: ContentLoader {
        ContentLoader(contentDirectory: Bundle.module.url(forResource: "Fixtures", withExtension: nil)!
            .appending(path: "Content"))
    }

    static var content: ContentStore { ContentStore(loader: fixtures) }

    /// A new empty folder in the temporary directory.
    static func temporaryDirectory() throws -> URL {
        let url = URL.temporaryDirectory.appending(path: "vybe-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A file to put in a test content folder.
    struct TestFile {
        let folder: String
        let name: String
        let text: String

        init(_ folder: String, _ name: String, _ text: String) {
            self.folder = folder
            self.name = name
            self.text = text
        }
    }

    /// A content folder containing the given files.
    static func contentFolder(_ files: [TestFile]) throws -> ContentLoader {
        let root = try temporaryDirectory()
        for file in files {
            let directory = root.appending(path: file.folder)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try file.text.write(to: directory.appending(path: file.name), atomically: true, encoding: .utf8)
        }
        return ContentLoader(contentDirectory: root)
    }
}
