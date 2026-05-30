import Foundation

struct MindDocument: Identifiable, Codable {
    let id: UUID
    var title: String
    var nodes: [UUID: MindNode]
    var rootNodeID: UUID
    var layoutType: LayoutType
    var canvasOffset: CGSize
    var canvasScale: CGFloat
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "Untitled",
        nodes: [UUID: MindNode] = [:],
        rootNodeID: UUID = UUID(),
        layoutType: LayoutType = .radial,
        canvasOffset: CGSize = .zero,
        canvasScale: CGFloat = 1.0
    ) {
        self.id = id
        self.title = title
        self.nodes = nodes
        self.rootNodeID = rootNodeID
        self.layoutType = layoutType
        self.canvasOffset = canvasOffset
        self.canvasScale = canvasScale
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var rootNode: MindNode? {
        nodes[rootNodeID]
    }

    func allDescendantIDs(of nodeID: UUID) -> [UUID] {
        var result: [UUID] = []
        guard let node = nodes[nodeID] else { return result }
        for childID in node.childrenIDs {
            result.append(childID)
            result.append(contentsOf: allDescendantIDs(of: childID))
        }
        return result
    }

    func flattenedNodes() -> [(UUID, MindNode)] {
        var result: [(UUID, MindNode)] = []
        func traverse(_ id: UUID, depth: Int = 0) {
            guard let node = nodes[id] else { return }
            result.append((id, node))
            if !node.isCollapsed {
                for childID in node.childrenIDs {
                    traverse(childID, depth: depth + 1)
                }
            }
        }
        traverse(rootNodeID)
        return result
    }

    static func createDefault() -> MindDocument {
        let root = MindNode(
            title: "Central Idea",
            position: CGPoint(x: 400, y: 400),
            isRoot: true
        )
        let child1 = MindNode(title: "Branch 1", position: CGPoint(x: 600, y: 300))
        let child2 = MindNode(title: "Branch 2", position: CGPoint(x: 600, y: 500))
        var doc = MindDocument(
            nodes: [
                root.id: root,
                child1.id: child1,
                child2.id: child2
            ],
            rootNodeID: root.id
        )
        doc.nodes[root.id]?.childrenIDs = [child1.id, child2.id]
        return doc
    }

    private static let documentsURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent("Mind0")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static func loadAll() -> [MindDocument] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: documentsURL,
            includingPropertiesForKeys: nil
        ) else { return [] }
        return files
            .filter { $0.pathExtension == "mind0" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url),
                      let doc = try? JSONDecoder().decode(MindDocument.self, from: data)
                else { return nil }
                return doc
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func save() {
        let url = Self.documentsURL.appendingPathComponent("\(title).mind0")
        var newDoc = self
        newDoc.updatedAt = Date()
        guard let newData = try? JSONEncoder().encode(newDoc) else { return }
        try? newData.write(to: url)
    }

    func delete() {
        let url = Self.documentsURL.appendingPathComponent("\(title).mind0")
        try? FileManager.default.removeItem(at: url)
    }
}

enum LayoutType: String, Codable, CaseIterable {
    case radial
    case tree

    var displayName: String {
        switch self {
        case .radial: "Radial (Center)"
        case .tree: "Tree (Left)"
        }
    }
}
