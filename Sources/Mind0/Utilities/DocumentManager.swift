import Foundation

final class DocumentManager {
    static let shared = DocumentManager()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var documentsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("com.mind0.app", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadAll() -> [MindDocument] {
        guard let files = try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        else { return [] }
        return files
            .filter { $0.pathExtension == "mind0" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url),
                      let doc = try? decoder.decode(MindDocument.self, from: data)
                else { return nil }
                return doc
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ document: MindDocument) {
        let url = documentsDirectory.appendingPathComponent("\(document.id.uuidString).mind0")
        var copy = document
        copy.updatedAt = Date()
        guard let data = try? encoder.encode(copy) else { return }
        try? data.write(to: url)
    }

    func delete(_ document: MindDocument) {
        let url = documentsDirectory.appendingPathComponent("\(document.id.uuidString).mind0")
        try? fileManager.removeItem(at: url)
    }
}
