import Foundation

struct MindDocument: Identifiable, Codable {
    let id: UUID
    var title: String
    var nodes: [UUID: MindNode]
    var rootNodeID: UUID
    var layoutType: LayoutType
    var lineStyle: LineStyle
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
        lineStyle: LineStyle = .curved,
        canvasOffset: CGSize = .zero,
        canvasScale: CGFloat = 1.0
    ) {
        self.id = id
        self.title = title
        self.nodes = nodes
        self.rootNodeID = rootNodeID
        self.layoutType = layoutType
        self.lineStyle = lineStyle
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
        flattenedNodes(showAll: [])
    }

    func flattenedNodes(showAll: Set<UUID>) -> [(UUID, MindNode)] {
        var result: [(UUID, MindNode)] = []
        func traverse(_ id: UUID) {
            guard let node = nodes[id] else { return }
            result.append((id, node))
            if !node.isCollapsed {
                let children = node.childrenIDs
                let maxChildren = showAll.contains(id) ? children.count : min(children.count, 5)
                for childID in children.prefix(maxChildren) {
                    traverse(childID)
                }
            }
        }
        traverse(rootNodeID)
        return result
    }

    struct ShowMoreInfo: Identifiable {
        let id: UUID
        let parentID: UUID
        let position: CGPoint
        let hiddenCount: Int
    }

    func showMoreButtonData(showAll: Set<UUID>) -> [ShowMoreInfo] {
        var result: [ShowMoreInfo] = []
        for (id, node) in nodes {
            guard !node.isCollapsed, node.childrenIDs.count > 5, !showAll.contains(id) else { continue }
            if let sixth = nodes[node.childrenIDs[5]] {
                result.append(ShowMoreInfo(
                    id: UUID(),
                    parentID: id,
                    position: sixth.position,
                    hiddenCount: node.childrenIDs.count - 5
                ))
            }
        }
        return result
    }

    static func createDefault() -> MindDocument {
        let root = MindNode(
            title: "Central Idea",
            position: CGPoint(x: 60, y: 150),
            isRoot: true
        )
        let child1 = MindNode(
            title: "Branch 1",
            position: CGPoint(x: 340, y: 90),
            backgroundColor: "#B5E2FA",
            shape: .roundedRect
        )
        let child2 = MindNode(
            title: "Branch 2",
            position: CGPoint(x: 340, y: 210),
            backgroundColor: "#CAFFBF",
            shape: .roundedRect
        )
        var doc = MindDocument(
            nodes: [
                root.id: root,
                child1.id: child1,
                child2.id: child2
            ],
            rootNodeID: root.id,
            layoutType: .tree
        )
        doc.nodes[root.id]?.childrenIDs = [child1.id, child2.id]
        return doc
    }
}

enum LayoutType: String, Codable, CaseIterable {
    case radial
    case tree
    case treeRight
    case treeUp
    case treeDown

    var displayName: String {
        switch self {
        case .radial: "Radial (Center)"
        case .tree: "Tree (Left)"
        case .treeRight: "Tree (Right)"
        case .treeUp: "Tree (Up)"
        case .treeDown: "Tree (Down)"
        }
    }
}

enum LineStyle: String, Codable, CaseIterable {
    case curved
    case orthogonal
    case straight

    var displayName: String {
        switch self {
        case .curved: "Curved"
        case .orthogonal: "Rounded Orthogonal"
        case .straight: "Straight"
        }
    }
}
