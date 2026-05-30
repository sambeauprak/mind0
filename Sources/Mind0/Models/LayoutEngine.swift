import Foundation

struct LayoutEngine {
    let nodeSize = CGSize(width: 180, height: 60)
    let horizontalSpacing: CGFloat = 100
    let verticalSpacing: CGFloat = 24
    let radialRadius: CGFloat = 160

    func applyRadialLayout(to document: inout MindDocument) {
        guard let root = document.nodes[document.rootNodeID] else { return }
        var updatedNodes = document.nodes
        updatedNodes[document.rootNodeID]?.position = root.position

        let visibleChildren = root.childrenIDs
        guard !visibleChildren.isEmpty else { return }

        let total = CGFloat(visibleChildren.count)
        for (index, childID) in visibleChildren.enumerated() {
            let angle = (2 * .pi * CGFloat(index) / total) - (.pi / 2)
            let childPos = CGPoint(
                x: root.position.x + cos(angle) * radialRadius,
                y: root.position.y + sin(angle) * radialRadius
            )
            updatedNodes[childID]?.position = childPos
            applyRadialLayoutRecursive(for: childID, in: &updatedNodes, parentPos: childPos, level: 1)
        }
        document.nodes = updatedNodes
    }

    private func applyRadialLayoutRecursive(for nodeID: UUID, in nodes: inout [UUID: MindNode], parentPos: CGPoint, level: Int) {
        guard let node = nodes[nodeID], !node.isCollapsed else { return }
        let visibleChildren = node.childrenIDs
        guard !visibleChildren.isEmpty else { return }

        let total = CGFloat(visibleChildren.count)
        let radius = radialRadius * CGFloat(level + 1) * 0.6
        for (index, childID) in visibleChildren.enumerated() {
            let angle = (2 * .pi * CGFloat(index) / total) - (.pi / 2)
            let childPos = CGPoint(
                x: parentPos.x + cos(angle) * radius,
                y: parentPos.y + sin(angle) * radius
            )
            nodes[childID]?.position = childPos
            applyRadialLayoutRecursive(for: childID, in: &nodes, parentPos: childPos, level: level + 1)
        }
    }

    func applyTreeLayout(to document: inout MindDocument) {
        guard let root = document.nodes[document.rootNodeID] else { return }

        let rootX: CGFloat = 60

        func calcSubtreeHeight(_ nodeID: UUID) -> CGFloat {
            guard let node = document.nodes[nodeID] else { return 0 }
            if node.isCollapsed || node.childrenIDs.isEmpty {
                return nodeSize.height
            }
            let childHeights = node.childrenIDs.map { calcSubtreeHeight($0) }
            let totalChild = childHeights.reduce(0, +)
            let spacing = CGFloat(node.childrenIDs.count - 1) * verticalSpacing
            return max(nodeSize.height, totalChild + spacing)
        }

        func layoutSubtree(_ nodeID: UUID, x: CGFloat, topY: CGFloat) -> CGFloat {
            guard let node = document.nodes[nodeID] else { return topY }

            let subtreeH = calcSubtreeHeight(nodeID)
            let nodeY = topY + subtreeH / 2
            document.nodes[nodeID]?.position = CGPoint(x: x, y: nodeY)

            if !node.isCollapsed, !node.childrenIDs.isEmpty {
                let childX = x + horizontalSpacing + nodeSize.width
                var childTopY = topY

                for childID in node.childrenIDs {
                    childTopY = layoutSubtree(childID, x: childX, topY: childTopY)
                    childTopY += calcSubtreeHeight(childID) + verticalSpacing
                }
            }

            return topY
        }

        // Position root
        let totalH = calcSubtreeHeight(root.id)
        document.nodes[root.id]?.position = CGPoint(x: rootX, y: totalH / 2)

        // Position children in a block starting at topY=0
        if !root.isCollapsed, !root.childrenIDs.isEmpty {
            let childX = rootX + horizontalSpacing + nodeSize.width
            var childTopY: CGFloat = 0

            // First pass: lay out all children sequentially from topY = 0
            for childID in root.childrenIDs {
                childTopY = layoutSubtree(childID, x: childX, topY: childTopY)
                childTopY += calcSubtreeHeight(childID) + verticalSpacing
            }

            // Second pass: compute the total children block height and center it on the root
            let allChildrenH = root.childrenIDs.reduce(0) { $0 + calcSubtreeHeight($1) }
                + CGFloat(root.childrenIDs.count - 1) * verticalSpacing
            let blockOffset = (totalH - allChildrenH) / 2

            // Apply block offset to all children recursively
            for childID in root.childrenIDs {
                offsetTree(childID, offset: blockOffset, document: &document)
            }
        }
    }

    private func offsetTree(_ nodeID: UUID, offset: CGFloat, document: inout MindDocument) {
        document.nodes[nodeID]?.position.y += offset
        guard let node = document.nodes[nodeID], !node.isCollapsed else { return }
        for childID in node.childrenIDs {
            offsetTree(childID, offset: offset, document: &document)
        }
    }
}
