import Foundation

struct LayoutEngine {
    let nodeSize = CGSize(width: 180, height: 80)
    let horizontalSpacing: CGFloat = 120
    let verticalSpacing: CGFloat = 60
    let radialRadius: CGFloat = 180

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
        guard document.nodes[document.rootNodeID] != nil else { return }

        func calcHeight(_ nodeID: UUID) -> CGFloat {
            guard let node = document.nodes[nodeID] else { return 0 }
            if node.isCollapsed || node.childrenIDs.isEmpty {
                return nodeSize.height
            }
            let childHeights = node.childrenIDs.map { calcHeight($0) }
            let totalChild = childHeights.reduce(0, +)
            let spacing = CGFloat(node.childrenIDs.count - 1) * verticalSpacing
            return max(nodeSize.height, totalChild + spacing)
        }

        func positionNode(_ nodeID: UUID, x: CGFloat, yRange: (min: CGFloat, max: CGFloat)) {
            guard let node = document.nodes[nodeID] else { return }

            let nodeY = (yRange.min + yRange.max) / 2
            document.nodes[nodeID]?.position = CGPoint(x: x, y: nodeY)

            if !node.isCollapsed {
                let children = node.childrenIDs
                let totalChildren = children.count
                let availableHeight = yRange.max - yRange.min - verticalSpacing * CGFloat(totalChildren - 1)
                let childHeight = max(nodeSize.height, availableHeight / CGFloat(totalChildren))
                var currentY = yRange.min

                for childID in children {
                    let childH = calcHeight(childID)
                    let childYRange = (
                        min: currentY,
                        max: currentY + max(childH, childHeight)
                    )
                    positionNode(
                        childID,
                        x: x + horizontalSpacing + nodeSize.width,
                        yRange: childYRange
                    )
                    currentY += max(childH, childHeight) + verticalSpacing
                }
            }
        }

        let totalHeight = calcHeight(document.rootNodeID)
        document.nodes[document.rootNodeID]?.position = CGPoint(x: 60, y: totalHeight / 2)

        let rootPos = document.nodes[document.rootNodeID]?.position ?? .zero
        let children = document.nodes[document.rootNodeID]?.childrenIDs ?? []

        var currentChildY: CGFloat = 0
        for childID in children {
            let h = calcHeight(childID)
            let childX = rootPos.x + horizontalSpacing + nodeSize.width
            positionNode(
                childID,
                x: childX,
                yRange: (min: currentChildY, max: currentChildY + h)
            )
            currentChildY += h + verticalSpacing
        }

        for childID in children {
            let childH = calcHeight(childID)
            let childMidY = (document.nodes[childID]?.position.y ?? 0) + childH / 2
            offsetTree(childID, offset: rootPos.y - childMidY, document: &document)
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
