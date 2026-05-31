import Foundation

struct LayoutEngine {
    let nodeSize = CGSize(width: 180, height: 60)
    let horizontalSpacing: CGFloat = 80
    let verticalSpacing: CGFloat = 60
    let radialRadius: CGFloat = 200
    let imagePadding: CGFloat = 40

    private func visibleChildren(of nodeID: UUID, nodes: [UUID: MindNode], showAll: Set<UUID>) -> [UUID] {
        guard let node = nodes[nodeID] else { return [] }
        let children = node.childrenIDs
        if showAll.contains(nodeID) {
            return children
        }
        return Array(children.prefix(5))
    }

    // MARK: - Radial Layout (Hybrid Radial–Tree)

    func applyRadialLayout(to document: inout MindDocument, center: CGPoint = CGPoint(x: 600, y: 400), showAll: Set<UUID> = []) {
        guard document.nodes[document.rootNodeID] != nil else { return }
        var updatedNodes = document.nodes

        updatedNodes[document.rootNodeID]?.position = center

        let topChildren = visibleChildren(of: document.rootNodeID, nodes: document.nodes, showAll: showAll)
        guard !topChildren.isEmpty else { return }

        placeSlice(topChildren, parentID: document.rootNodeID, parentPos: center, center: center, start: 0, end: 2 * .pi, level: 1, nodes: &updatedNodes, showAll: showAll)
        document.nodes = updatedNodes
    }

    // ── Constants ─────────────────────────────────────────────────
    let maxRadius: CGFloat = 1000
    let minAngularSpacing: CGFloat = 5 * .pi / 180   // 5°
    let denseThreshold = 10

    private func placeSlice(_ children: [UUID], parentID: UUID, parentPos: CGPoint, center: CGPoint, start: CGFloat, end: CGFloat, level: Int, nodes: inout [UUID: MindNode], showAll: Set<UUID>) {
        guard let parent = nodes[parentID] else { return }

        // ── Layout decision ─────────────────────────────────────────
        if let override = parent.childrenLayout {
            switch override {
            case .tree:
                placeTreeCluster(children, parentPos: parentPos, direction: .tree, nodes: &nodes, showAll: showAll)
                return
            case .treeRight:
                placeTreeCluster(children, parentPos: parentPos, direction: .treeRight, nodes: &nodes, showAll: showAll)
                return
            case .treeUp:
                placeTreeCluster(children, parentPos: parentPos, direction: .treeUp, nodes: &nodes, showAll: showAll)
                return
            case .treeDown:
                placeTreeCluster(children, parentPos: parentPos, direction: .treeDown, nodes: &nodes, showAll: showAll)
                return
            case .radial:
                break
            }
        } else if children.count >= denseThreshold {
            placeTreeCluster(children, parentPos: parentPos, direction: .tree, nodes: &nodes, showAll: showAll)
            return
        }

        // ── Radial placement ────────────────────────────────────────
        let count = CGFloat(children.count)
        let step = (end - start) / count

        let marginRatio: CGFloat = 0.05
        let margin = step * marginRatio
        let usable = step - 2 * margin

        var maxWidth: CGFloat = nodeSize.width
        for cid in children {
            guard let child = nodes[cid] else { continue }
            if child.imageData != nil || child.imagePath != nil {
                maxWidth = max(maxWidth, nodeSize.width + 40)
            }
            if child.imageCoverMode {
                maxWidth = max(maxWidth, nodeSize.width + 60)
            }
        }

        let rawHalfSep = step / 2
        let halfSep = max(rawHalfSep, minAngularSpacing / 2)

        let minRadius: CGFloat
        if count > 1, halfSep > 0 {
            minRadius = (maxWidth / 2) / sin(halfSep)
        } else {
            minRadius = 0
        }
        let levelBoost: CGFloat = 1.0 + CGFloat(level - 1) * 0.25
        let baseRadius = (radialRadius + imagePadding) * CGFloat(level) * levelBoost
        let radius = min(max(baseRadius, minRadius), maxRadius)

        for (i, childID) in children.enumerated() {
            let childStart = start + step * CGFloat(i) + margin
            let childEnd   = childStart + usable
            let angle      = (childStart + childEnd) / 2

            nodes[childID]?.position = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )

            guard let node = nodes[childID], !node.isCollapsed else { continue }
            let grandchildren = visibleChildren(of: childID, nodes: nodes, showAll: showAll)
            if !grandchildren.isEmpty {
                placeSlice(grandchildren, parentID: childID, parentPos: nodes[childID]!.position, center: center, start: childStart, end: childEnd, level: level + 1, nodes: &nodes, showAll: showAll)
            }
        }
    }

    /// Tree cluster for dense branches (≥10 children or manual override).
    private func placeTreeCluster(_ children: [UUID], parentPos: CGPoint, direction: LayoutType, nodes: inout [UUID: MindNode], showAll: Set<UUID>) {
        let stepX = nodeSize.width + horizontalSpacing
        let stepY = nodeSize.height + verticalSpacing
        let isVertical = direction == .treeUp || direction == .treeDown
        let slotSpacing = isVertical ? stepX : stepY
        let slotSize = isVertical ? nodeSize.width : nodeSize.height

        func leafCount(_ id: UUID) -> Int {
            guard let n = nodes[id] else { return 0 }
            if n.isCollapsed { return 1 }
            let c = visibleChildren(of: id, nodes: nodes, showAll: showAll)
            if c.isEmpty { return 1 }
            return c.reduce(0) { $0 + leafCount($1) }
        }

        var leafCache: [UUID: Int] = [:]
        var totalLeaves = 0
        for cid in children {
            let l = leafCount(cid)
            leafCache[cid] = l
            totalLeaves += l
        }
        let totalSpan = CGFloat(totalLeaves) * slotSize + CGFloat(totalLeaves - 1) * (slotSpacing - slotSize)
        let baseSlotPos: CGFloat
        switch direction {
        case .tree, .treeRight:
            baseSlotPos = parentPos.y - totalSpan / 2
        case .treeUp, .treeDown:
            baseSlotPos = parentPos.x - totalSpan / 2
        default:
            baseSlotPos = 0
        }

        @discardableResult
        func place(_ id: UUID, depth: Int, slot: Int) -> Int {
            guard let n = nodes[id] else { return 0 }
            let leaves = leafCache[id] ?? leafCount(id)
            leafCache[id] = leaves
            let blockSpan = CGFloat(leaves) * slotSize + CGFloat(leaves - 1) * (slotSpacing - slotSize)
            let slotPos = baseSlotPos + CGFloat(slot) * slotSpacing + blockSpan / 2

            let point: CGPoint
            switch direction {
            case .tree:
                point = CGPoint(x: parentPos.x + CGFloat(depth) * stepX, y: slotPos)
            case .treeRight:
                point = CGPoint(x: parentPos.x - CGFloat(depth) * stepX, y: slotPos)
            case .treeUp:
                point = CGPoint(x: slotPos, y: parentPos.y - CGFloat(depth) * stepY)
            case .treeDown:
                point = CGPoint(x: slotPos, y: parentPos.y + CGFloat(depth) * stepY)
            default:
                point = .zero
            }
            nodes[id]?.position = point

            if !n.isCollapsed {
                let c = visibleChildren(of: id, nodes: nodes, showAll: showAll)
                if !c.isEmpty {
                    var s = 0
                    for cid in c {
                        if leafCache[cid] == nil {
                            leafCache[cid] = leafCount(cid)
                        }
                        s += place(cid, depth: depth + 1, slot: slot + s)
                    }
                }
            }
            return leaves
        }

        var slot = 0
        for cid in children {
            slot += place(cid, depth: 1, slot: slot)
        }
    }

    // MARK: - Tree Layout (XMind-style)

    func applyTreeLayout(to document: inout MindDocument, direction: LayoutType = .tree, showAll: Set<UUID> = []) {
        guard let root = document.nodes[document.rootNodeID] else { return }

        let depthStart: CGFloat = 60
        let stepX = nodeSize.width + horizontalSpacing
        let stepY = nodeSize.height + verticalSpacing
        let isVertical = direction == .treeUp || direction == .treeDown
        let slotSpacing = isVertical ? stepX : stepY
        let slotSize = isVertical ? nodeSize.width : nodeSize.height

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
            let blockSpan = CGFloat(leaves) * slotSize + CGFloat(leaves - 1) * (slotSpacing - slotSize)
            let slotPos = CGFloat(slot) * slotSpacing + blockSpan / 2

            let point: CGPoint
            switch direction {
            case .tree:
                point = CGPoint(x: depthStart + CGFloat(depth) * stepX, y: slotPos)
            case .treeRight:
                point = CGPoint(x: depthStart - CGFloat(depth) * stepX, y: slotPos)
            case .treeUp:
                point = CGPoint(x: slotPos, y: depthStart - CGFloat(depth) * stepY)
            case .treeDown:
                point = CGPoint(x: slotPos, y: depthStart + CGFloat(depth) * stepY)
            case .radial:
                point = .zero
            }
            document.nodes[id]?.position = point

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
