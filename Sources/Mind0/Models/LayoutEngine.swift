import Foundation

struct LayoutEngine {
    let nodeSize = CGSize(width: 180, height: 60)
    let horizontalSpacing: CGFloat = 80
    let verticalSpacing: CGFloat = 60
    let radialRadius: CGFloat = 160

    private func visibleChildren(of nodeID: UUID, nodes: [UUID: MindNode], showAll: Set<UUID>) -> [UUID] {
        guard let node = nodes[nodeID] else { return [] }
        let children = node.childrenIDs
        if showAll.contains(nodeID) {
            return children
        }
        return Array(children.prefix(5))
    }

    // MARK: - Radial Layout

    func applyRadialLayout(to document: inout MindDocument, showAll: Set<UUID> = []) {
        guard let root = document.nodes[document.rootNodeID] else { return }
        var updatedNodes = document.nodes
        updatedNodes[document.rootNodeID]?.position = root.position
        let children = visibleChildren(of: document.rootNodeID, nodes: document.nodes, showAll: showAll)
        guard !children.isEmpty else { return }

        let total = CGFloat(children.count)
        for (i, childID) in children.enumerated() {
            let angle = (2 * .pi * CGFloat(i) / total) - (.pi / 2)
            let pos = CGPoint(
                x: root.position.x + cos(angle) * radialRadius,
                y: root.position.y + sin(angle) * radialRadius
            )
            updatedNodes[childID]?.position = pos
            radialRecurse(childID, parentPos: pos, level: 1, nodes: &updatedNodes, showAll: showAll)
        }
        document.nodes = updatedNodes
    }

    private func radialRecurse(_ nodeID: UUID, parentPos: CGPoint, level: Int, nodes: inout [UUID: MindNode], showAll: Set<UUID>) {
        guard let node = nodes[nodeID], !node.isCollapsed else { return }
        let children = visibleChildren(of: nodeID, nodes: nodes, showAll: showAll)
        guard !children.isEmpty else { return }
        let total = CGFloat(children.count)
        let radius = radialRadius * CGFloat(level + 1) * 0.6
        for (i, childID) in children.enumerated() {
            let angle = (2 * .pi * CGFloat(i) / total) - (.pi / 2)
            let pos = CGPoint(
                x: parentPos.x + cos(angle) * radius,
                y: parentPos.y + sin(angle) * radius
            )
            nodes[childID]?.position = pos
            radialRecurse(childID, parentPos: pos, level: level + 1, nodes: &nodes, showAll: showAll)
        }
    }

    // MARK: - Tree Layout (XMind-style)

    func applyTreeLayout(to document: inout MindDocument, showAll: Set<UUID> = []) {
        guard let root = document.nodes[document.rootNodeID] else { return }

        let rootX: CGFloat = 60
        let stepX = nodeSize.width + horizontalSpacing

        func leafCount(_ id: UUID) -> Int {
            guard let n = document.nodes[id] else { return 0 }
            if n.isCollapsed { return 1 }
            let children = visibleChildren(of: id, nodes: document.nodes, showAll: showAll)
            if children.isEmpty { return 1 }
            return children.reduce(0) { $0 + leafCount($1) }
        }

        @discardableResult
        func place(_ id: UUID, depth: Int, slot: Int) -> Int {
            guard let n = document.nodes[id] else { return 0 }
            let leaves = leafCount(id)
            let blockH = CGFloat(leaves) * nodeSize.height + CGFloat(leaves - 1) * verticalSpacing
            let y = CGFloat(slot) * (nodeSize.height + verticalSpacing) + blockH / 2
            let x = rootX + CGFloat(depth) * stepX
            document.nodes[id]?.position = CGPoint(x: x, y: y)

            if !n.isCollapsed {
                let children = visibleChildren(of: id, nodes: document.nodes, showAll: showAll)
                if !children.isEmpty {
                    var s = slot
                    for cid in children {
                        s += place(cid, depth: depth + 1, slot: s)
                    }
                }
            }
            return leaves
        }

        place(root.id, depth: 0, slot: 0)
    }
}
