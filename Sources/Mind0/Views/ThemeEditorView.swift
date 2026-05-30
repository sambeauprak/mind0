import SwiftUI

struct ThemeEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedThemeID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Themes")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.escape)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(Theme.presets) { theme in
                        themeCard(theme)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 520, height: 480)
    }

    private func themeCard(_ theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: theme.lineColor) ?? .blue)
                    .frame(width: 12, height: 12)

                Text(theme.name)
                    .font(.system(size: 12, weight: .semibold))

                Spacer()

                if appState.currentTheme.id == theme.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14))
                }
            }

            HStack(spacing: 6) {
                shapePreview(shape: theme.nodeShape, color: theme.nodeBackgroundColor)
                Text(theme.nodeShape.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                if theme.imageCoverMode {
                    Label("Cover", systemImage: "photo.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Label("Canvas", systemImage: "square.fill")
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.canvasBackgroundColor) ?? .gray)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(appState.currentTheme.id == theme.id ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: appState.currentTheme.id == theme.id ? 2 : 1)
        )
        .onTapGesture {
            appState.applyTheme(theme)
        }
    }

    private func shapePreview(shape: NodeShape, color: String) -> some View {
        Group {
            switch shape {
            case .roundedRect:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: color) ?? .white)
                    .frame(width: 28, height: 16)
            case .ellipse:
                Ellipse()
                    .fill(Color(hex: color) ?? .white)
                    .frame(width: 28, height: 16)
            case .capsule:
                Capsule()
                    .fill(Color(hex: color) ?? .white)
                    .frame(width: 28, height: 16)
            case .rectangle:
                Rectangle()
                    .fill(Color(hex: color) ?? .white)
                    .frame(width: 28, height: 16)
            }
        }
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
