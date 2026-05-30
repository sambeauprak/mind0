import SwiftUI

struct NodeCardView: View {
    let nodeID: UUID
    @EnvironmentObject var appState: AppState
    @State private var isHovered: Bool = false
    @State private var showColorPicker: Bool = false
    @State private var isEditing: Bool = false
    @State private var editText: String = ""
    @State private var dragStartPos: CGPoint = .zero

    private let cardWidth: CGFloat = 180
    private let cardHeight: CGFloat = 80

    private var node: MindNode? {
        appState.currentDocument?.nodes[nodeID]
    }

    var body: some View {
        if let node = node {
            VStack(spacing: 0) {
                if node.imageCoverMode, let img = loadedImage {
                    imageCoverContent(img, node: node)
                } else {
                    standardContent(node: node)
                }
            }
            .frame(width: cardWidth, height: node.imageCoverMode && loadedImage != nil ? 120 : cardHeight)
            .background(
                shapeView(node: node)
                    .fill(node.backgroundColorSwift)
                    .shadow(color: .black.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 6 : 3, y: isHovered ? 3 : 1)
            )
            .overlay(
                shapeView(node: node)
                    .stroke(appState.selectedNodeIDs.contains(nodeID) ? Color.accentColor : Color.clear, lineWidth: 2.5)
            )
            .clipShape(shapeView(node: node))
            .overlay(alignment: .topTrailing) {
                if isHovered, nodeID != appState.currentDocument?.rootNodeID {
                    collapseButton(node: node)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isHovered {
                    addButton
                        .offset(x: -4, y: -4)
                }
            }
            .overlay(alignment: .topLeading) {
                if isHovered {
                    colorButton
                        .offset(x: 4, y: 4)
                }
            }
            .onHover { hovering in
                isHovered = hovering
            }
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        if appState.draggingNodeID != nodeID {
                            appState.draggingNodeID = nodeID
                            dragStartPos = node.position
                        }
                        let translation = value.translation
                        let newPos = CGPoint(
                            x: dragStartPos.x + translation.width / appState.canvasScale,
                            y: dragStartPos.y + translation.height / appState.canvasScale
                        )
                        appState.updateNodePosition(nodeID, position: newPos)
                    }
                    .onEnded { _ in
                        appState.draggingNodeID = nil
                        appState.saveCurrentDocument()
                    }
            )
            .onTapGesture {
                appState.selectedNodeIDs = [nodeID]
            }
            .onTapGesture(count: 2) {
                editText = node.title
                isEditing = true
            }
            .contextMenu {
                NodeContextMenu(nodeID: nodeID)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $isEditing) {
                editSheet
            }
            .popover(isPresented: $showColorPicker) {
                ColorPickerView(nodeID: nodeID, node: node)
                    .environmentObject(appState)
            }
        }
    }

    private var loadedImage: NSImage? {
        guard let node = node else { return nil }
        return node.swiftUIImage(availableImages: appState.loadedImages)
    }

    @ViewBuilder
    private func standardContent(node: MindNode) -> some View {
        VStack(spacing: 2) {
            if let img = loadedImage, !node.imageCoverMode {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth - 8, height: 48)
                    .clipped()
                    .cornerRadius(4)
                    .onTapGesture {
                        appState.previewImage = img
                        appState.showImagePreview = true
                    }
            }

            Text(node.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: appState.currentTheme.nodeTextColor) ?? .primary)
                .lineLimit(3)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .frame(maxWidth: cardWidth, maxHeight: cardHeight)
    }

    @ViewBuilder
    private func imageCoverContent(_ img: NSImage, node: MindNode) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(nsImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: 120)
                .clipped()

            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )

            Text(node.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(8)
        }
        .onTapGesture {
            appState.previewImage = img
            appState.showImagePreview = true
        }
    }

    private func shapeView(node: MindNode) -> AnyShape {
        switch node.shape {
        case .roundedRect:
            AnyShape(RoundedRectangle(cornerRadius: 8))
        case .ellipse:
            AnyShape(Ellipse())
        case .capsule:
            AnyShape(Capsule())
        case .rectangle:
            AnyShape(Rectangle())
        }
    }

    private func collapseButton(node: MindNode) -> some View {
        Button(action: { appState.toggleCollapse(nodeID) }) {
            Image(systemName: node.isCollapsed ? "chevron.right.circle.fill" : "chevron.down.circle.fill")
                .foregroundColor(.white)
                .background(Circle().fill(Color.black.opacity(0.4)))
                .font(.system(size: 14))
        }
        .buttonStyle(.plain)
        .help(node.isCollapsed ? "Expand" : "Collapse")
    }

    private var addButton: some View {
        Button(action: { appState.addChild(to: nodeID) }) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.green)
                .background(Circle().fill(Color.white))
                .font(.system(size: 16))
        }
        .buttonStyle(.plain)
        .help("Add Child")
    }

    private var colorButton: some View {
        Button(action: { showColorPicker.toggle() }) {
            Image(systemName: "paintbrush.fill")
                .foregroundColor(node?.backgroundColorSwift ?? .white)
                .font(.system(size: 12))
                .padding(3)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .buttonStyle(.plain)
        .help("Change Color")
    }

    private var editSheet: some View {
        VStack(spacing: 16) {
            Text("Edit Node")
                .font(.headline)

            TextField("Title", text: $editText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)

            HStack {
                Button("Cancel") { isEditing = false }
                    .keyboardShortcut(.escape)

                Button("Save") {
                    appState.updateNodeTitle(nodeID, title: editText)
                    isEditing = false
                }
                .keyboardShortcut(.return)
            }
        }
        .padding(24)
        .frame(width: 320)
    }
}

struct NodeContextMenu: View {
    let nodeID: UUID
    @EnvironmentObject var appState: AppState

    private var node: MindNode? {
        appState.currentDocument?.nodes[nodeID]
    }

    var body: some View {
        Group {
            Button("Add Child") { appState.addChild(to: nodeID) }
                .keyboardShortcut("n")

            Button("Edit Title") { appState.editingNodeID = nodeID }

            Divider()

            Button("Toggle Collapse") { appState.toggleCollapse(nodeID) }
                .keyboardShortcut("c", modifiers: [.command, .shift])

            Divider()

            Button("Add Image...") { addImage() }
            if node?.imageData != nil || node?.imagePath != nil {
                Button("Remove Image") { appState.removeNodeImage(nodeID) }
            }

            Divider()

            if nodeID != appState.currentDocument?.rootNodeID {
                Button("Delete Node", role: .destructive) { appState.deleteNode(nodeID) }
            }
        }
    }

    private func addImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let image = NSImage(contentsOf: url) {
            appState.setNodeImage(nodeID, image: image)
        }
    }
}
