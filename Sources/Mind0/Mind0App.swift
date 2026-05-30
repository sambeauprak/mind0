import SwiftUI

@main
struct Mind0App: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    appState.loadDocuments()
                }
        }
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    appState.undo()
                }
                .keyboardShortcut("z", modifiers: .command)

                Button("Redo") {
                    appState.redo()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            CommandMenu("Node") {
                Button("Add Child Node") {
                    if let selectedID = appState.selectedNodeIDs.first {
                        appState.addChild(to: selectedID)
                    }
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Delete Node") {
                    if let selectedID = appState.selectedNodeIDs.first {
                        appState.deleteNode(selectedID)
                    }
                }
                .keyboardShortcut(.delete, modifiers: .command)

                Divider()

                Button("Toggle Collapse") {
                    if let selectedID = appState.selectedNodeIDs.first {
                        appState.toggleCollapse(selectedID)
                    }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            CommandMenu("Layout") {
                Button("Radial Layout") {
                    appState.setLayoutType(.radial)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])

                Button("Tree Layout") {
                    appState.setLayoutType(.tree)
                }
                .keyboardShortcut("2", modifiers: [.command, .option])
            }

            CommandMenu("Export") {
                Button("Export as SVG") {
                    appState.exportAsSVG()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Export as Markdown") {
                    appState.exportAsMarkdown()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }
    }
}
