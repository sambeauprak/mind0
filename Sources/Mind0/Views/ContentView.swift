import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var newDocTitle: String = "Untitled"

    var body: some View {
        HSplitView {
            if appState.sidebarVisible {
                SidebarView()
                    .frame(minWidth: 200, idealWidth: 240, maxWidth: 360)
                    .layoutPriority(1)
            }

            CanvasView()
                .frame(minWidth: 500)
                .layoutPriority(2)
        }
        .overlay(alignment: .topLeading) {
            if !appState.sidebarVisible && !appState.isPresenting {
                Button(action: { appState.sidebarVisible = true }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Show Sidebar")
                .padding(.leading, 4)
            }
        }
        .overlay(alignment: .topTrailing) {
            if !appState.isPresenting {
                HStack(spacing: 4) {
                Button(action: { appState.applyLayout() }) {
                    Label("Layout", systemImage: "arrow.triangle.2.circlepath")
                }
                .labelStyle(.iconOnly)
                .help("Auto Layout")

                Picker("Layout", selection: Binding(
                    get: { appState.currentDocument?.layoutType ?? .radial },
                    set: { appState.setLayoutType($0) }
                )) {
                    ForEach(LayoutType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .controlSize(.small)

                Divider()
                    .frame(height: 14)

                Picker("Line Style", selection: Binding(
                    get: { appState.currentDocument?.lineStyle ?? .curved },
                    set: { appState.setLineStyle($0) }
                )) {
                    ForEach(LineStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                .controlSize(.small)

                Divider()
                    .frame(height: 14)

                Button(action: { appState.isExporting = true }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .labelStyle(.iconOnly)
                .help("Export")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .padding(10)
            }
        }
        .sheet(isPresented: $appState.isExporting) {
            ExportView()
                .environmentObject(appState)
        }
        .overlay {
            if appState.showImagePreview, let image = appState.previewImage {
                ImagePreviewView(image: image)
                    .environmentObject(appState)
            }
        }
        .alert("New Document", isPresented: $appState.showNewDocAlert) {
            TextField("Document Name", text: $newDocTitle)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                let title = newDocTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                appState.newDocument(title: title.isEmpty ? "Untitled" : title)
            }
        } message: {
            Text("Enter a name for the new document.")
        }
    }
}
