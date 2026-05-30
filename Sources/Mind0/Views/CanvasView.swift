import SwiftUI

struct CanvasView: View {
    @EnvironmentObject var appState: AppState
    @State private var isPanning: Bool = false
    @State private var panStartOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: appState.currentTheme.canvasBackgroundColor) ?? Color(nsColor: .windowBackgroundColor)

                if appState.isPresenting {
                    Color.black.opacity(0.45)
                        .allowsHitTesting(false)
                }

                if let doc = appState.currentDocument {
                    ZStack {
                        ConnectionLinesView(doc: doc, theme: appState.currentTheme, lineStyle: doc.lineStyle, highlightedNodeID: appState.presentationHighlightNodeID)
                        ForEach(doc.flattenedNodes(), id: \.0) { (id, node) in
                            NodeCardView(nodeID: id)
                                .environmentObject(appState)
                                .position(node.position)
                        }
                    }
                    .scaleEffect(appState.canvasScale, anchor: .topLeading)
                    .offset(appState.canvasOffset)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        if !isPanning {
                            isPanning = true
                            panStartOffset = appState.canvasOffset
                        }
                        appState.canvasOffset = CGSize(
                            width: panStartOffset.width + value.translation.width,
                            height: panStartOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        isPanning = false
                    }
            )
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    let scaleBefore = appState.canvasScale
                    if event.modifierFlags.contains(.command) {
                        let delta = Float(event.deltaY) * 0.001
                        appState.canvasScale = max(0.1, min(5.0, appState.canvasScale + CGFloat(delta)))
                        let mouseInWindow = event.locationInWindow
                        let viewPoint = CGPoint(
                            x: (mouseInWindow.x - appState.canvasOffset.width) / scaleBefore,
                            y: (mouseInWindow.y - appState.canvasOffset.height) / scaleBefore
                        )
                        appState.canvasOffset = CGSize(
                            width: mouseInWindow.x - viewPoint.x * appState.canvasScale,
                            height: mouseInWindow.y - viewPoint.y * appState.canvasScale
                        )
                        return nil
                    }
                    appState.canvasOffset = CGSize(
                        width: appState.canvasOffset.width + event.deltaX,
                        height: appState.canvasOffset.height - event.deltaY
                    )
                    return nil
                }
            }
            .overlay(alignment: .bottomTrailing) {
                canvasControls(geometry: geometry)
            }
            .overlay(alignment: .top) {
                if appState.isPresenting {
                    presentationBar
                        .zIndex(100)
                }
            }
            .onChange(of: appState.presentationIndex) { _, _ in
                focusOnCurrentPresentationNode(geometry: geometry)
            }
            .onChange(of: appState.isPresenting) { _, newValue in
                if newValue {
                    focusOnCurrentPresentationNode(geometry: geometry)
                }
            }
        }
    }

    @ViewBuilder
    private var presentationBar: some View {
        HStack(spacing: 12) {
            Button(action: { appState.previousPresentationNode() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
            }
            .keyboardShortcut(.leftArrow, modifiers: [])

            if appState.presentationIndex < appState.presentationOrder.count {
                let (_, node) = appState.presentationOrder[appState.presentationIndex]
                Text(node.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .frame(maxWidth: 200)
                Text("\(appState.presentationIndex + 1) / \(appState.presentationOrder.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: { appState.nextPresentationNode() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .keyboardShortcut(.rightArrow, modifiers: [])

            Divider()
                .frame(height: 14)

            Button(action: { appState.exitPresentation() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .keyboardShortcut(.escape, modifiers: [])
            .help("Exit Presentation (Esc)")
        }
        .buttonStyle(.plain)
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    @ViewBuilder
    private func canvasControls(geometry: GeometryProxy) -> some View {
        HStack(spacing: 6) {
            Button(action: { fitAllNodes(geometry: geometry) }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11))
            }
            .help("Zoom to Fit All")

            Button(action: { centerOnRoot(geometry: geometry) }) {
                Image(systemName: "location")
                    .font(.system(size: 11))
            }
            .help("Center on Root")

            Divider()
                .frame(height: 12)

            Button(action: { appState.enterPresentation() }) {
                Image(systemName: "play.rectangle")
                    .font(.system(size: 11))
            }
            .help("Presentation Mode (→ / ←)")

            Divider()
                .frame(height: 12)

            Button(action: { appState.canvasScale = max(0.1, appState.canvasScale - 0.15) }) {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
            }

            Text("\(Int(appState.canvasScale * 100))%")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 32)

            Button(action: { appState.canvasScale = min(5.0, appState.canvasScale + 0.15) }) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .padding(12)
    }

    private func fitAllNodes(geometry: GeometryProxy) {
        guard let doc = appState.currentDocument, geometry.size.width > 0, geometry.size.height > 0 else { return }
        let allNodes = doc.flattenedNodes()
        guard !allNodes.isEmpty else { return }

        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for (_, node) in allNodes {
            minX = min(minX, node.position.x)
            minY = min(minY, node.position.y)
            maxX = max(maxX, node.position.x + 180)
            maxY = max(maxY, node.position.y + 80)
        }

        let pad: CGFloat = 60
        let contentW = maxX - minX + pad * 2
        let contentH = maxY - minY + pad * 2
        let scaleX = (geometry.size.width - pad) / contentW
        let scaleY = (geometry.size.height - pad) / contentH
        let newScale = max(0.1, min(scaleX, scaleY, 2.0))

        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2

        withAnimation(.easeInOut(duration: 0.25)) {
            appState.canvasScale = newScale
            appState.canvasOffset = CGSize(
                width: geometry.size.width / 2 - centerX * newScale,
                height: geometry.size.height / 2 - centerY * newScale
            )
        }
    }

    private func centerOnRoot(geometry: GeometryProxy) {
        guard let doc = appState.currentDocument, let root = doc.nodes[doc.rootNodeID], geometry.size.width > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            appState.canvasScale = 1.0
            appState.canvasOffset = CGSize(
                width: geometry.size.width / 2 - root.position.x,
                height: geometry.size.height / 2 - root.position.y
            )
        }
    }

    private func focusOnCurrentPresentationNode(geometry: GeometryProxy) {
        guard appState.isPresenting,
              appState.presentationIndex < appState.presentationOrder.count,
              geometry.size.width > 0 else { return }
        let (_, node) = appState.presentationOrder[appState.presentationIndex]
        withAnimation(.easeInOut(duration: 0.35)) {
            appState.canvasScale = 1.6
            appState.canvasOffset = CGSize(
                width: geometry.size.width / 2 - node.position.x * 1.6,
                height: geometry.size.height / 2 - node.position.y * 1.6
            )
        }
    }
}

struct ConnectionLinesView: View {
    let doc: MindDocument
    let theme: Theme
    let lineStyle: LineStyle
    let highlightedNodeID: UUID?

    struct Connection: Identifiable {
        let id: String
        let from: CGPoint
        let to: CGPoint
        let color: Color
        let isHighlighted: Bool
    }

    var connections: [Connection] {
        let visibleIDs = Set(doc.flattenedNodes().map { $0.0 })
        return doc.nodes.flatMap { parentID, parent in
            return parent.childrenIDs.compactMap { childID in
                guard visibleIDs.contains(parentID), visibleIDs.contains(childID) else { return nil }
                guard let child = doc.nodes[childID] else { return nil }
                let color = Color(hex: parent.lineColor)
                    ?? Color(hex: theme.lineColor)
                    ?? .blue
                let isHighlighted = highlightedNodeID == parentID || highlightedNodeID == childID
                return Connection(
                    id: "\(parentID.uuidString)-\(childID.uuidString)",
                    from: parent.position,
                    to: child.position,
                    color: color,
                    isHighlighted: isHighlighted
                )
            }
        }
    }

    var body: some View {
        let dimmed = highlightedNodeID != nil
        ForEach(connections) { conn in
            ConnectionPath(from: conn.from, to: conn.to, color: conn.color, lineStyle: lineStyle)
                .opacity(dimmed && !conn.isHighlighted ? 0.15 : 1.0)
        }
    }
}

struct ConnectionPath: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    let lineStyle: LineStyle
    private let cornerRadius: CGFloat = 12

    var body: some View {
        Path { path in
            switch lineStyle {
            case .curved:
                drawCurved(path: &path)
            case .orthogonal:
                drawOrthogonal(path: &path)
            }
        }
        .stroke(color, style: SwiftUI.StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }

    private func drawCurved(path: inout Path) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let controlOffsetX = abs(dx) * 0.5
        let controlOffsetY = abs(dy) * 0.3

        path.move(to: from)
        path.addCurve(
            to: to,
            control1: CGPoint(x: from.x + controlOffsetX, y: from.y + controlOffsetY),
            control2: CGPoint(x: to.x - controlOffsetX, y: to.y - controlOffsetY)
        )
    }

    private func drawOrthogonal(path: inout Path) {
        let midX = (from.x + to.x) / 2
        let r = min(cornerRadius, abs(from.y - to.y) / 2, abs(midX - from.x))

        path.move(to: from)
        path.addLine(to: CGPoint(x: midX, y: from.y))
        path.addArc(tangent1End: CGPoint(x: midX, y: to.y), tangent2End: to, radius: max(r, 1))
        path.addLine(to: to)
    }
}
