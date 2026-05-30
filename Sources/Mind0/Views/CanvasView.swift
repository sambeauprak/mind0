import SwiftUI

struct CanvasView: View {
    @EnvironmentObject var appState: AppState
    @State private var isPanning: Bool = false
    @State private var panStartOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: appState.currentTheme.canvasBackgroundColor) ?? Color(white: 0.96)

                if let doc = appState.currentDocument {
                    ZStack {
                        ConnectionLinesView(doc: doc, theme: appState.currentTheme)
                        ForEach(doc.flattenedNodes(), id: \.0) { (id, _) in
                            NodeCardView(nodeID: id)
                                .environmentObject(appState)
                        }
                    }
                    .scaleEffect(appState.canvasScale, anchor: .topLeading)
                    .offset(appState.canvasOffset)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        if appState.draggingNodeID == nil {
                            if !isPanning {
                                isPanning = true
                                panStartOffset = appState.canvasOffset
                            }
                            appState.canvasOffset = CGSize(
                                width: panStartOffset.width + value.translation.width,
                                height: panStartOffset.height + value.translation.height
                            )
                        }
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
        }
    }

    @ViewBuilder
    private func canvasControls(geometry: GeometryProxy) -> some View {
        VStack(spacing: 6) {
            Button(action: { fitAllNodes(geometry: geometry) }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right.circle")
                    .font(.system(size: 14))
            }
            .help("Zoom to Fit All Nodes")

            Button(action: { centerOnRoot(geometry: geometry) }) {
                Image(systemName: "location.circle")
                    .font(.system(size: 14))
            }
            .help("Center on Root")

            HStack(spacing: 4) {
                Button(action: { appState.canvasScale = max(0.1, appState.canvasScale - 0.15) }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 12))
                }
                Text("\(Int(appState.canvasScale * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 36)
                Button(action: { appState.canvasScale = min(5.0, appState.canvasScale + 0.15) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 12))
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
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
}

struct ConnectionLinesView: View {
    let doc: MindDocument
    let theme: Theme

    var body: some View {
        ZStack {
            ForEach(Array(doc.nodes.keys), id: \.self) { parentID in
                if let parent = doc.nodes[parentID], !parent.isCollapsed {
                    ForEach(parent.childrenIDs, id: \.self) { childID in
                        if let child = doc.nodes[childID] {
                            let lineColor = Color(hex: parent.lineColor) ?? Color(hex: theme.lineColor) ?? .blue
                            ConnectionPath(from: parent.position, to: child.position, color: lineColor)
                        }
                    }
                }
            }
        }
    }
}

struct ConnectionPath: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color

    var body: some View {
        Path { path in
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
        .stroke(color, style: SwiftUI.StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }
}
