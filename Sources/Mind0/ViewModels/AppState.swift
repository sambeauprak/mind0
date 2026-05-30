import SwiftUI
import UniformTypeIdentifiers

class AppState: ObservableObject {
    @Published var documents: [MindDocument] = []
    @Published var currentDocumentID: UUID? {
        didSet {
            if let id = currentDocumentID {
                UserDefaults.standard.set(id.uuidString, forKey: "activeDocumentID")
            } else {
                UserDefaults.standard.removeObject(forKey: "activeDocumentID")
            }
            guard oldValue != currentDocumentID else { return }
            if let oldID = oldValue, var oldDoc = documents.first(where: { $0.id == oldID }) {
                oldDoc.canvasScale = canvasScale
                oldDoc.canvasOffset = canvasOffset
                documentManager.save(oldDoc)
            }
            centerOnRoot()
        }
    }
    @Published var selectedNodeIDs: Set<UUID> = []
    @Published var sidebarVisible: Bool = true
    @Published var canvasScale: CGFloat = 1.0
    @Published var canvasOffset: CGSize = .zero
    @Published var editingNodeID: UUID?
    @Published var isExporting: Bool = false
    @Published var showImagePreview: Bool = false
    @Published var previewImage: NSImage?
    @Published var loadedImages: [String: NSImage] = [:]
    @Published var showExportPanel: Bool = false
    @Published var showNewDocAlert: Bool = false
    @Published var isPresenting: Bool = false
    @Published var presentationIndex: Int = 0
    var presentationOrder: [(UUID, MindNode)] = []

    var presentationHighlightNodeID: UUID? {
        isPresenting && presentationIndex < presentationOrder.count ? presentationOrder[presentationIndex].0 : nil
    }

    private let documentManager = DocumentManager.shared
    private var undoStack: [MindDocument] = []
    private var redoStack: [MindDocument] = []
    private let maxUndoCount = 20

    var currentDocument: MindDocument? {
        get { documents.first(where: { $0.id == currentDocumentID }) }
        set {
            if let newValue = newValue {
                if let index = documents.firstIndex(where: { $0.id == currentDocumentID }) {
                    documents[index] = newValue
                }
            }
        }
    }

    func saveUndoState() {
        guard let doc = currentDocument else { return }
        if let data = try? JSONEncoder().encode(doc),
           let copy = try? JSONDecoder().decode(MindDocument.self, from: data) {
            undoStack.append(copy)
            if undoStack.count > maxUndoCount {
                undoStack.removeFirst()
            }
            redoStack.removeAll()
        }
    }

    func undo() {
        guard !undoStack.isEmpty, let doc = currentDocument else { return }
        if let data = try? JSONEncoder().encode(doc),
           let copy = try? JSONDecoder().decode(MindDocument.self, from: data) {
            redoStack.append(copy)
        }
        let previous = undoStack.removeLast()
        currentDocument = previous
        canvasScale = previous.canvasScale
        canvasOffset = previous.canvasOffset
        saveCurrentDocument()
    }

    func redo() {
        guard !redoStack.isEmpty, let doc = currentDocument else { return }
        if let data = try? JSONEncoder().encode(doc),
           let copy = try? JSONDecoder().decode(MindDocument.self, from: data) {
            undoStack.append(copy)
        }
        let next = redoStack.removeLast()
        currentDocument = next
        canvasScale = next.canvasScale
        canvasOffset = next.canvasOffset
        saveCurrentDocument()
    }

    func saveCurrentDocument() {
        guard var doc = currentDocument else { return }
        doc.canvasScale = canvasScale
        doc.canvasOffset = canvasOffset
        currentDocument = doc
        documentManager.save(doc)
    }

    func newDocument(title: String = "Untitled") {
        var doc = MindDocument.createDefault()
        doc.title = title
        documents.insert(doc, at: 0)
        currentDocumentID = doc.id
        applyLayout()
        centerOnRoot()
        saveCurrentDocument()
    }

    func centerOnRoot() {
        guard let doc = currentDocument, let root = doc.nodes[doc.rootNodeID] else { return }
        canvasScale = 1.0
        canvasOffset = CGSize(
            width: 60 - root.position.x,
            height: 40 - root.position.y
        )
    }

    func enterPresentation() {
        guard let doc = currentDocument else { return }
        sidebarVisible = false
        var order: [(UUID, MindNode)] = []
        var queue: [UUID] = [doc.rootNodeID]
        while !queue.isEmpty {
            let id = queue.removeFirst()
            guard let node = doc.nodes[id] else { continue }
            order.append((id, node))
            if !node.isCollapsed {
                queue.append(contentsOf: node.childrenIDs)
            }
        }
        presentationOrder = order
        presentationIndex = 0
        isPresenting = true
    }

    func exitPresentation() {
        isPresenting = false
        presentationOrder = []
        centerOnRoot()
    }

    func nextPresentationNode() {
        guard isPresenting, !presentationOrder.isEmpty else { return }
        presentationIndex = min(presentationIndex + 1, presentationOrder.count - 1)
    }

    func previousPresentationNode() {
        guard isPresenting, !presentationOrder.isEmpty else { return }
        presentationIndex = max(presentationIndex - 1, 0)
    }

    func loadDocuments() {
        documents = documentManager.loadAll()

        if let savedID = UserDefaults.standard.string(forKey: "activeDocumentID"),
           let uuid = UUID(uuidString: savedID),
           documents.contains(where: { $0.id == uuid }) {
            currentDocumentID = uuid
        }

        if currentDocumentID == nil {
            if documents.isEmpty {
                newDocument()
                return
            }
            currentDocumentID = documents.first!.id
        }

        applyLayout()
        centerOnRoot()
    }

    func deleteDocument(_ id: UUID) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }

        if id == currentDocumentID {
            saveCurrentDocument()
        }

        documentManager.delete(doc)
        documents = documentManager.loadAll()

        if currentDocumentID == id {
            if let next = documents.first {
                currentDocumentID = next.id
                canvasScale = next.canvasScale
                canvasOffset = next.canvasOffset
                selectedNodeIDs = []
            } else {
                currentDocumentID = nil
                canvasScale = 1.0
                canvasOffset = .zero
            }
        }
    }

    func addChild(to parentID: UUID) {
        guard var doc = currentDocument else { return }
        saveUndoState()
        let child = MindNode(title: "New Node")
        doc.nodes[child.id] = child
        doc.nodes[parentID]?.childrenIDs.append(child.id)
        currentDocument = doc
        applyLayout()
        saveCurrentDocument()
    }

    func deleteNode(_ nodeID: UUID) {
        guard var doc = currentDocument else { return }
        saveUndoState()
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
        saveUndoState()
        doc.nodes[nodeID]?.isCollapsed.toggle()
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodeTitle(_ nodeID: UUID, title: String) {
        guard var doc = currentDocument else { return }
        saveUndoState()
        doc.nodes[nodeID]?.title = title
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodePosition(_ nodeID: UUID, position: CGPoint) {
        guard var doc = currentDocument else { return }
        saveUndoState()
        doc.nodes[nodeID]?.position = position
        currentDocument = doc
        saveCurrentDocument()
    }

    func setNodePosition(_ nodeID: UUID, position: CGPoint) {
        guard var doc = currentDocument else { return }
        doc.nodes[nodeID]?.position = position
        currentDocument = doc
    }

    func updateNodeColor(_ nodeID: UUID, color: String) {
        guard var doc = currentDocument else { return }
        saveUndoState()
        doc.nodes[nodeID]?.backgroundColor = color
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodeShape(_ nodeID: UUID, shape: NodeShape) {
        guard var doc = currentDocument else { return }
        saveUndoState()
        doc.nodes[nodeID]?.shape = shape
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodeLineColor(_ nodeID: UUID, color: String) {
        guard var doc = currentDocument else { return }
        saveUndoState()
        doc.nodes[nodeID]?.lineColor = color
        currentDocument = doc
        saveCurrentDocument()
    }

    func updateNodeImageCoverMode(_ nodeID: UUID, enabled: Bool) {
        guard var doc = currentDocument else { return }
        saveUndoState()
        doc.nodes[nodeID]?.imageCoverMode = enabled
        currentDocument = doc
        saveCurrentDocument()
    }

    func setNodeImage(_ nodeID: UUID, image: NSImage) {
        guard var doc = currentDocument else { return }
        saveUndoState()
        if let data = image.tiffRepresentation {
            doc.nodes[nodeID]?.imageData = data
        }
        currentDocument = doc
        saveCurrentDocument()
    }

    func removeNodeImage(_ nodeID: UUID) {
        guard var doc = currentDocument else { return }
        saveUndoState()
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
        saveUndoState()
        doc.layoutType = type
        currentDocument = doc
        applyLayout()
    }

    func setLineStyle(_ style: LineStyle) {
        guard var doc = currentDocument else { return }
        saveUndoState()
        doc.lineStyle = style
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
