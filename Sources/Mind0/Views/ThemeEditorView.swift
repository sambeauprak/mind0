import SwiftUI

struct ThemeEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedThemeID: UUID?

    var body: some View {
        VStack(spacing: 20) {
            Text("Theme Editor")
                .font(.title2)
                .fontWeight(.semibold)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                    ForEach(Theme.presets) { theme in
                        themeCard(theme)
                    }
                }
                .padding()
            }

            HStack {
                Button("Close") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(width: 520, height: 460)
    }

    private func themeCard(_ theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: theme.lineColor) ?? .blue)
                    .frame(width: 14, height: 14)

                Text(theme.name)
                    .font(.system(size: 13, weight: .semibold))

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
                    Label("Image Cover", systemImage: "photo.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Label("Canvas", systemImage: "square.fill")
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.canvasBackgroundColor) ?? .gray)
            }
        }
        .padding(12)
        .background(Color(hex: theme.canvasBackgroundColor) ?? Color(white: 0.95))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(appState.currentTheme.id == theme.id ? Color.accentColor : Color.clear, lineWidth: 2)
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
                    .frame(width: 30, height: 18)
            case .ellipse:
                Ellipse()
                    .fill(Color(hex: color) ?? .white)
                    .frame(width: 30, height: 18)
            case .capsule:
                Capsule()
                    .fill(Color(hex: color) ?? .white)
                    .frame(width: 30, height: 18)
            case .rectangle:
                Rectangle()
                    .fill(Color(hex: color) ?? .white)
                    .frame(width: 30, height: 18)
            }
        }
        .overlay(
            Rectangle()
                .stroke(Color(hex: color)?.opacity(0.3) ?? Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
