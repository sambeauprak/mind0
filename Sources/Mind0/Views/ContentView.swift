import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HSplitView {
            if appState.sidebarVisible {
                SidebarView()
                    .frame(minWidth: 220, idealWidth: 260, maxWidth: 400)
                    .layoutPriority(1)
            }

            CanvasView()
                .frame(minWidth: 600)
                .layoutPriority(2)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 6) {
                Button(action: { appState.sidebarVisible.toggle() }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar")

                Button(action: { appState.applyLayout() }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
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
                .frame(width: 160)

                Button(action: { appState.showThemeEditor = true }) {
                    Image(systemName: "paintpalette")
                }
                .help("Themes")

                Divider()
                    .frame(height: 16)

                Button(action: { appState.isExporting = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Export")
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .padding(8)
        }
        .sheet(isPresented: $appState.showThemeEditor) {
            ThemeEditorView()
        }
        .sheet(isPresented: $appState.isExporting) {
            ExportView()
        }
        .overlay {
            if appState.showImagePreview, let image = appState.previewImage {
                ImagePreviewView(image: image)
                    .environmentObject(appState)
            }
        }
    }
}
