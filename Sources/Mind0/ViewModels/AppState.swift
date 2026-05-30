import SwiftUI
import UniformTypeIdentifiers

class AppState: ObservableObject {
    @Published var documents: [MindDocument] = []
    @Published var currentDocumentID: UUID?
    @Published var selectedNodeIDs: Set<UUID> = []
    @Published var currentTheme: Theme = .presets[0]
    @Published var sidebarVisible: Bool = true
    @Published var canvasScale: CGFloat = 1.0
    @Published var canvasOffset: CGSize = .zero
    @Published var editingNodeID: UUID?
    @Published var isExporting: Bool = false
    @Published var showImagePreview: Bool = false
    @Published var previewImage: NSImage?
    @Published var showThemeEditor: Bool = false
    @Published var loadedImages: [String: NSImage] = [:]
    @Published var draggingNodeID: UUID?
    var dragNodeStartPos: CGPoint = .zero
    @Published var showExportPanel: Bool = false

    var currentDocument: MindDocument? {
        get {
            documents.first(where: { $0.id == currentDocumentID })
        }
        set {
            if let newValue = newValue {
                if let index = documents.firstIndex(where: { $0.id == currentDocumentID }) {
                    documents[index] = newValue
                }
            }
        }
    }

    func saveCurrentDocument() {
        guard var doc = currentDocument else { return }
        doc.canvasScale = canvasScale
        doc.canvasOffset = canvasOffset
        currentDocument = doc
        doc.save()
        documents = MindDocument.loadAll()
        if let reloaded = documents.first(where: { $0.id == doc.id }) {
            if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
                documents[idx] = reloaded
            }
        }
    }

    func newDocument() {
        let doc = MindDocument.createDefault()
        documents.insert(doc, at: 0)
        currentDocumentID = doc.id
        applyLayout()
        centerOnRoot()
        saveCurrentDocument()
        documents = MindDocument.loadAll()
    }

    func centerOnRoot() {
        guard let doc = currentDocument, let root = doc.nodes[doc.rootNodeID] else { return }
        canvasScale = 1.0
        canvasOffset = CGSize(
            width: 60 - root.position.x,
            height: 40 - root.position.y
        )
    }

    func loadDocuments() {
        documents = MindDocument.loadAll()
        if documents.isEmpty {
            newDocument()
        } else {
            let first = documents.first!
            currentDocumentID = first.id
            canvasScale = first.canvasScale
            canvasOffset = first.canvasOffset
            if isDocumentStale(first) {
                applyLayout()
            }
        }
    }

    private func isDocumentStale(_ doc: MindDocument) -> Bool {
        guard let root = doc.nodes[doc.rootNodeID] else { return false }
        return root.position == .zero || root.position == CGPoint(x: 60, y: 150)
    }

    func deleteDocument(_ id: UUID) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }
        doc.delete()
        documents = MindDocument.loadAll()
        if currentDocumentID == id {
            currentDocumentID = documents.first?.id
        }
    }

    func addChild(to parentID: UUID) {
        guard var doc = currentDocument else { return }
        let child = MindNode(title: "New Node")
        doc.nodes[child.id] = child
        doc.nodes[parentID]?.childrenIDs.append(child.id)
        currentDocument = doc
        applyLayout()
        saveCurrentDocument()
    }

    func deleteNode(_ nodeID: UUID) {
        guard var doc = currentDocument else { return }
        if nodeID == doc.rootNodeID { return }
        let allDescendants = doc.allDescendantIDs(of: nodeID)
        for descID in allDescendants {
            doc.nodes.removeValue(forKey: descID)
        }
        doc.nodes.removeValue(forKey: nodeID)
        for (key, _) in doc.nodes {
            doc.nodes[key]?.childrenIDs.removeAll { $0 == nodeID || allDescendants.contains($0) }
        }
        selectedNodeIDs.remove(nodeID)
        currentDocument = doc
        saveCurrentDocument()
    }

    func toggleCollapse(_ nodeID: UUID) {
        guard var doc = currentDocument else { return }
        doc.nodes[nodeID]?.isCollapsed.toggle()
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodePosition(_ nodeID: UUID, position: CGPoint) {
        guard var doc = currentDocument else { return }
        doc.nodes[nodeID]?.position = position
        currentDocument = doc
    }

    func updateNodeTitle(_ nodeID: UUID, title: String) {
        guard var doc = currentDocument else { return }
        doc.nodes[nodeID]?.title = title
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodeColor(_ nodeID: UUID, color: String) {
        guard var doc = currentDocument else { return }
        doc.nodes[nodeID]?.backgroundColor = color
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodeShape(_ nodeID: UUID, shape: NodeShape) {
        guard var doc = currentDocument else { return }
        doc.nodes[nodeID]?.shape = shape
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodeLineColor(_ nodeID: UUID, color: String) {
        guard var doc = currentDocument else { return }
        doc.nodes[nodeID]?.lineColor = color
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodeImageCoverMode(_ nodeID: UUID, enabled: Bool) {
        guard var doc = currentDocument else { return }
        doc.nodes[nodeID]?.imageCoverMode = enabled
        currentDocument = doc
        saveCurrentDocument()
    }

    func setNodeImage(_ nodeID: UUID, image: NSImage) {
        guard var doc = currentDocument else { return }
        if let data = image.tiffRepresentation {
            doc.nodes[nodeID]?.imageData = data
        }
        currentDocument = doc
        saveCurrentDocument()
    }

    func removeNodeImage(_ nodeID: UUID) {
        guard var doc = currentDocument else { return }
        doc.nodes[nodeID]?.imageData = nil
        doc.nodes[nodeID]?.imagePath = nil
        doc.nodes[nodeID]?.imageCoverMode = false
        currentDocument = doc
        saveCurrentDocument()
    }

    func applyLayout() {
        guard var doc = currentDocument else { return }
        let engine = LayoutEngine()
        switch doc.layoutType {
        case .radial:
            engine.applyRadialLayout(to: &doc)
        case .tree:
            engine.applyTreeLayout(to: &doc)
        }
        currentDocument = doc
        saveCurrentDocument()
    }

    func setLayoutType(_ type: LayoutType) {
        guard var doc = currentDocument else { return }
        doc.layoutType = type
        currentDocument = doc
        applyLayout()
    }

    func applyTheme(_ theme: Theme) {
        currentTheme = theme
        guard var doc = currentDocument else { return }
        for (id, _) in doc.nodes {
            doc.nodes[id]?.shape = theme.nodeShape
            doc.nodes[id]?.lineColor = theme.lineColor
            if id == doc.rootNodeID || theme.nodeBackgroundColor != "#FFFFFF" {
                doc.nodes[id]?.backgroundColor = theme.nodeBackgroundColor
            }
            doc.nodes[id]?.imageCoverMode = theme.imageCoverMode
        }
        currentDocument = doc
        saveCurrentDocument()
    }

    func exportAsSVG() {
        guard let doc = currentDocument else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.svg]
        panel.nameFieldStringValue = doc.title
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let svg = SVGExporter.export(doc: doc)
        try? svg.write(to: url, atomically: true, encoding: .utf8)
    }

    func exportAsMarkdown() {
        guard let doc = currentDocument else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.canChooseFiles = false
        panel.message = "Choose a directory to export markdown files"
        guard panel.runModal() == .OK, let dirURL = panel.url else { return }
        MarkdownExporter.export(doc: doc, to: dirURL)
    }
}
