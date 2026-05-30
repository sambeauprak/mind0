import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var docToDelete: MindDocument?

    var body: some View {
        List(selection: $appState.currentDocumentID) {
            Section("Documents") {
                ForEach(appState.documents) { doc in
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 11))

                        Text(doc.title)
                            .font(.system(size: 12, weight: doc.id == appState.currentDocumentID ? .semibold : .regular))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: { docToDelete = doc }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 16, height: 16)
                                .background(Color(nsColor: .quaternaryLabelColor).opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .opacity(doc.id == appState.currentDocumentID ? 0.6 : 0)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("Delete", role: .destructive) { docToDelete = doc }
                    }
                    .tag(doc.id)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        docToDelete = appState.documents[index]
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
        .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
        .toolbar {
            ToolbarItem {
                Button(action: { appState.showNewDocAlert = true }) {
                    Image(systemName: "plus")
                }
                .help("New Document")
            }
        }
        .confirmationDialog(
            "Delete Document",
            isPresented: Binding(
                get: { docToDelete != nil },
                set: { if !$0 { docToDelete = nil } }
            ),
            presenting: docToDelete
        ) { doc in
            Button("Delete", role: .destructive) {
                appState.deleteDocument(doc.id)
                docToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                docToDelete = nil
            }
        } message: { doc in
            Text("Are you sure you want to delete \"\(doc.title)\"? This action cannot be undone.")
        }
    }
}

struct NodeTreeView: View {
    let nodeID: UUID
    let depth: Int
    @EnvironmentObject var appState: AppState
    @State private var isHovered: Bool = false

    private var siblingIndex: (parentID: UUID, index: Int, total: Int)? {
        guard let doc = appState.currentDocument else { return nil }
        for (pid, pnode) in doc.nodes {
            if let idx = pnode.childrenIDs.firstIndex(of: nodeID) {
                return (pid, idx, pnode.childrenIDs.count)
            }
        }
        return nil
    }

    var body: some View {
        if let node = appState.currentDocument?.nodes[nodeID] {
            HStack(spacing: 4) {
                if !node.childrenIDs.isEmpty {
                    Button(action: { appState.toggleCollapse(nodeID) }) {
                        Image(systemName: node.isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 12, height: 16)
                } else {
                    Spacer().frame(width: 12)
                }

                Circle()
                    .fill(node.backgroundColorSwift)
                    .frame(width: 7, height: 7)

                Text(node.title)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(appState.selectedNodeIDs.contains(nodeID) ? .accentColor : .primary)

                if isHovered {
                    HStack(spacing: 2) {
                        if let info = siblingIndex {
                            if info.index > 0 {
                                Button(action: { appState.moveChild(nodeID, by: -1) }) {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 8, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .help("Move Up")
                            }
                            if info.index < info.total - 1 {
                                Button(action: { appState.moveChild(nodeID, by: 1) }) {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 8, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .help("Move Down")
                            }
                        }

                        Button(action: { appState.addChild(to: nodeID) }) {
                            Image(systemName: "plus")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .help("Add Child")

                        if nodeID != appState.currentDocument?.rootNodeID {
                            Button(role: .destructive, action: { appState.deleteNode(nodeID) }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 8))
                            }
                            .buttonStyle(.plain)
                            .help("Delete Node")
                        }
                    }
                    .foregroundColor(.secondary)
                    .transition(.opacity)
                }

                if !isHovered, nodeID == appState.currentDocument?.rootNodeID {
                    Image(systemName: "house.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .help("Root Node")
                }
            }
            .padding(.leading, CGFloat(depth) * 12)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .onTapGesture {
                appState.selectedNodeIDs = [nodeID]
            }
            .contextMenu {
                Button("Add Child") { appState.addChild(to: nodeID) }
                if nodeID != appState.currentDocument?.rootNodeID {
                    if let info = siblingIndex {
                        if info.index > 0 {
                            Button("Move Up") { appState.moveChild(nodeID, by: -1) }
                        }
                        if info.index < info.total - 1 {
                            Button("Move Down") { appState.moveChild(nodeID, by: 1) }
                        }
                    }
                    Divider()
                    Button("Delete", role: .destructive) { appState.deleteNode(nodeID) }
                }
            }

            if !node.isCollapsed {
                let children = node.childrenIDs
                let maxChildren = appState.childrenShowAll.contains(nodeID) ? children.count : min(children.count, 5)
                ForEach(children.prefix(maxChildren), id: \.self) { childID in
                    NodeTreeView(nodeID: childID, depth: depth + 1)
                        .environmentObject(appState)
                }
                if children.count > 5, !appState.childrenShowAll.contains(nodeID) {
                    Button(action: { appState.toggleShowAllChildren(nodeID) }) {
                        HStack(spacing: 4) {
                            Text("...")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("+\(children.count - 5) more")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, CGFloat(depth + 1) * 12 + 16)
                    .help("Show \(children.count - 5) more children")
                }
            }
        }
    }
}
