import SwiftUI

struct CanvasView: View {
    @EnvironmentObject var appState: AppState
    @State private var isPanning: Bool = false
    @State private var panStartOffset: CGSize = .zero

    var body: some View {
        GeometryReader { _ in
            let scale = appState.canvasScale
            let offset = appState.canvasOffset

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
                    .scaleEffect(scale)
                    .offset(offset)
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
                            let translation = value.translation
                            appState.canvasOffset = CGSize(
                                width: panStartOffset.width + translation.width / scale,
                                height: panStartOffset.height + translation.height / scale
                            )
                        }
                    }
                    .onEnded { _ in
                        isPanning = false
                        if let doc = appState.currentDocument {
                            appState.canvasOffset = doc.canvasOffset
                        }
                    }
            )
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    if event.modifierFlags.contains(.command) {
                        let delta = Float(event.deltaY) * 0.001
                        appState.canvasScale = max(0.2, min(5.0, appState.canvasScale + CGFloat(delta)))
                        return nil
                    }
                    return event
                }
            }
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
                control1: CGPoint(
                    x: from.x + controlOffsetX,
                    y: from.y + controlOffsetY
                ),
                control2: CGPoint(
                    x: to.x - controlOffsetX,
                    y: to.y - controlOffsetY
                )
            )
        }
        .stroke(color, style: SwiftUI.StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }
}
