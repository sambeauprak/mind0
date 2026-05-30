import SwiftUI

struct NodeCardView: View {
    let nodeID: UUID
    @EnvironmentObject var appState: AppState
    @State private var isHovered: Bool = false
    @State private var showColorPicker: Bool = false
    @State private var editText: String = ""
    @State private var isEditingLocally: Bool = false
    @State private var dragStartPosition: CGPoint = .zero
    @State private var didSaveUndoForDrag: Bool = false
    @FocusState private var isFocused: Bool

    private let cardWidth: CGFloat = 180
    private let cardHeight: CGFloat = 80

    private var node: MindNode? {
        appState.currentDocument?.nodes[nodeID]
    }

    var body: some View {
        if let node = node {
            cardContent(node: node)
                .onHover { hovering in
                    isHovered = hovering
                }
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            if !didSaveUndoForDrag {
                                appState.saveUndoState()
                                dragStartPosition = node.position
                                didSaveUndoForDrag = true
                            }
                            let scale = appState.canvasScale
                            let delta = value.translation
                            let newPos = CGPoint(
                                x: dragStartPosition.x + delta.width / scale,
                                y: dragStartPosition.y + delta.height / scale
                            )
                            appState.updateNodePosition(nodeID, position: newPos)
                        }
                        .onEnded { _ in
                            didSaveUndoForDrag = false
                            appState.saveCurrentDocument()
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            editText = node.title
                            isEditingLocally = true
                        }
                )
                .onTapGesture {
                    appState.selectedNodeIDs = [nodeID]
                }
                .contextMenu {
                    NodeContextMenu(nodeID: nodeID)
                        .environmentObject(appState)
                }
                .popover(isPresented: $showColorPicker) {
                    ColorPickerView(nodeID: nodeID, node: node)
                        .environmentObject(appState)
                }
                .onChange(of: appState.editingNodeID) { _, newID in
                    if newID == nodeID {
                        editText = node.title
                        isEditingLocally = true
                        appState.editingNodeID = nil
                    }
                }
                .onChange(of: isEditingLocally) { _, newValue in
                    if newValue {
                        isFocused = true
                    }
                }
                .onChange(of: appState.selectedNodeIDs) { _, newIDs in
                    if !newIDs.contains(nodeID) {
                        isEditingLocally = false
                    }
                }
                .opacity(appState.isPresenting && appState.presentationHighlightNodeID != nodeID ? 0.25 : 1.0)
                .zIndex(appState.isPresenting && appState.presentationHighlightNodeID == nodeID ? 10 : 0)
        }
    }

    private func cardContent(node: MindNode) -> some View {
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
                .shadow(color: .black.opacity(isHovered ? 0.18 : 0.08), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
        )
        .overlay(selectionStroke(node: node))
        .overlay(presentationStroke(node: node))
        .clipShape(shapeView(node: node))
        .overlay(alignment: .topTrailing) {
            if isHovered, nodeID != appState.currentDocument?.rootNodeID {
                collapseButton(node: node)
                    .padding(4)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            colorDot
                .padding(4)
        }
        .overlay(alignment: .topLeading) {
            if isHovered {
                HStack(spacing: 2) {
                    editButton
                    imageButton
                    addButton
                }
                .padding(4)
            }
        }
    }

    private func selectionStroke(node: MindNode) -> some View {
        shapeView(node: node)
            .stroke(appState.selectedNodeIDs.contains(nodeID) ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: appState.selectedNodeIDs.contains(nodeID) ? 2.5 : 1)
    }

    private func presentationStroke(node: MindNode) -> some View {
        shapeView(node: node)
            .stroke(appState.presentationHighlightNodeID == nodeID ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: appState.presentationHighlightNodeID == nodeID ? 4 : 0)
            .shadow(color: appState.presentationHighlightNodeID == nodeID ? Color.accentColor.opacity(0.5) : .clear, radius: 8)
    }

    private var loadedImage: NSImage? {
        guard let node = node else { return nil }
        return node.swiftUIImage(availableImages: appState.loadedImages)
    }

    @ViewBuilder
    private func standardContent(node: MindNode) -> some View {
        let textColor = textColorForBackground(node.backgroundColorSwift)
        VStack(spacing: 2) {
            if let img = loadedImage, !node.imageCoverMode {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth - 8, height: 48)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .onTapGesture {
                        appState.previewImage = img
                        appState.showImagePreview = true
                    }
                    .padding(.top, 4)
            }

            if isEditingLocally {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .onSubmit { saveEdit() }
                    .onExitCommand { isEditingLocally = false }
                    .padding(.horizontal, 10)
                    .padding(.vertical, loadedImage == nil ? 12 : 4)
            } else {
                Text(node.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor)
                    .lineLimit(3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, loadedImage == nil ? 12 : 4)
            }
        }
        .frame(maxWidth: cardWidth, maxHeight: cardHeight)
    }

    private func textColorForBackground(_ color: Color) -> Color {
        guard let nsColor = NSColor(color).usingColorSpace(.sRGB) else {
            return .primary
        }
        let r = nsColor.redComponent
        let g = nsColor.greenComponent
        let b = nsColor.blueComponent
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.6 ? Color(white: 0.2) : .white
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

            if isEditingLocally {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .onSubmit { saveEdit() }
                    .onExitCommand { isEditingLocally = false }
                    .padding(10)
            } else {
                Text(node.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .padding(10)
            }
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
                .background(Circle().fill(Color.black.opacity(0.35)))
                .font(.system(size: 13))
        }
        .buttonStyle(.plain)
        .help(node.isCollapsed ? "Expand" : "Collapse")
    }

    private var addButton: some View {
        Button(action: { appState.addChild(to: nodeID) }) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.green)
                .background(Circle().fill(Color.white.opacity(0.9)))
                .font(.system(size: 15))
        }
        .buttonStyle(.plain)
        .help("Add Child")
    }

    private var colorDot: some View {
        Button(action: { showColorPicker.toggle() }) {
            Circle()
                .fill(node?.backgroundColorSwift ?? .white)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.15), radius: 2)
        }
        .buttonStyle(.plain)
        .help("Change Color")
    }

    private var editButton: some View {
        Button(action: {
            guard let n = node else { return }
            editText = n.title
            isEditingLocally = true
        }) {
            Image(systemName: "pencil")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(3)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .buttonStyle(.plain)
        .help("Edit Title")
    }

    private var imageButton: some View {
        Button(action: { pickImage() }) {
            Image(systemName: "photo")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(3)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .buttonStyle(.plain)
        .help("Add Image")
    }

    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            appState.updateNodeTitle(nodeID, title: trimmed)
        }
        isEditingLocally = false
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let image = NSImage(contentsOf: url) {
                appState.setNodeImage(nodeID, image: image)
            }
        }
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
            Button("Add Child Node") { appState.addChild(to: nodeID) }
                .keyboardShortcut("n")

            Button("Edit Title") {
                if appState.currentDocument?.nodes[nodeID] != nil {
                    appState.editingNodeID = nodeID
                }
            }

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
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.allowsMultipleSelection = false
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            guard panel.runModal() == .OK, let url = panel.url else { return }
            if let image = NSImage(contentsOf: url) {
                appState.setNodeImage(nodeID, image: image)
            }
        }
    }
}
