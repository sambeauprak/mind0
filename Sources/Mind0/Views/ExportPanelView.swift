import SwiftUI

struct ExportView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("Export Mind Map")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                Button(action: {
                    appState.exportAsSVG()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "square.on.square")
                        Text("Export as SVG")
                        Spacer()
                        Text("Vector graphic")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(white: 0.95))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    appState.exportAsMarkdown()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Export as Markdown")
                        Spacer()
                        Text("Each node = 1 .md file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(white: 0.95))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            Button("Cancel") { dismiss() }
                .keyboardShortcut(.escape)
        }
        .padding(32)
        .frame(width: 360)
    }
}
