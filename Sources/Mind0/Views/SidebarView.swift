import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            Section("Documents") {
                ForEach(appState.documents) { doc in
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.accentColor)

                        Text(doc.title)
                            .font(.system(size: 13, weight: doc.id == appState.currentDocumentID ? .semibold : .regular))

                        Spacer()

                        if doc.id != appState.currentDocumentID {
                            Button(action: { appState.deleteDocument(doc.id) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if var currentDoc = appState.currentDocument {
                            currentDoc.canvasScale = appState.canvasScale
                            currentDoc.canvasOffset = appState.canvasOffset
                            appState.currentDocument = currentDoc
                            currentDoc.save()
                        }
                        appState.currentDocumentID = doc.id
                        appState.canvasScale = doc.canvasScale
                        appState.canvasOffset = doc.canvasOffset
                        appState.selectedNodeIDs = []
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        appState.deleteDocument(appState.documents[index].id)
                    }
                }
            }

            if let doc = appState.currentDocument {
                Section("Nodes") {
                    NodeTreeView(nodeID: doc.rootNodeID, depth: 0)
                        .environmentObject(appState)
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Button(action: { appState.newDocument() }) {
                    Image(systemName: "plus")
                }
                .help("New Document")
            }
        }
    }
}

struct NodeTreeView: View {
    let nodeID: UUID
    let depth: Int
    @EnvironmentObject var appState: AppState

    var body: some View {
        if let node = appState.currentDocument?.nodes[nodeID] {
            HStack(spacing: 2) {
                if !node.childrenIDs.isEmpty {
                    Button(action: { appState.toggleCollapse(nodeID) }) {
                        Image(systemName: node.isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 12)
                } else {
                    Spacer().frame(width: 12)
                }

                Circle()
                    .fill(node.backgroundColorSwift)
                    .frame(width: 8, height: 8)

                Text(node.title)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundColor(appState.selectedNodeIDs.contains(nodeID) ? .accentColor : .primary)

                Spacer()

                if nodeID == appState.currentDocument?.rootNodeID {
                    Image(systemName: "house.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, CGFloat(depth) * 14)
            .contentShape(Rectangle())
            .onTapGesture {
                appState.selectedNodeIDs = [nodeID]
            }
            .contextMenu {
                Button("Add Child") { appState.addChild(to: nodeID) }
                if nodeID != appState.currentDocument?.rootNodeID {
                    Button("Delete", role: .destructive) { appState.deleteNode(nodeID) }
                }
            }

            if !node.isCollapsed {
                ForEach(node.childrenIDs, id: \.self) { childID in
                    NodeTreeView(nodeID: childID, depth: depth + 1)
                        .environmentObject(appState)
                }
            }
        }
    }
}
