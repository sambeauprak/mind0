import SwiftUI

struct ColorPickerView: View {
    let nodeID: UUID
    let node: MindNode
    @EnvironmentObject var appState: AppState
    @State private var showCustomPicker: Bool = false
    @State private var customColor: Color = .white

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Node Color")
                .font(.system(size: 12, weight: .semibold))

            Text("Primary Colors")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(MindNode.presetColors, id: \.hex) { colorInfo in
                    colorButton(colorInfo.hex, colorInfo.name)
                }
            }

            Text("Pastel Colors")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(MindNode.presetColors, id: \.pastel) { colorInfo in
                    colorButton(colorInfo.pastel, colorInfo.name + " Pastel")
                }
            }

            Divider()

            Button(action: { showCustomPicker.toggle() }) {
                HStack {
                    Circle()
                        .fill(customColor)
                        .frame(width: 16, height: 16)
                    Text("Custom Color...")
                        .font(.system(size: 12))
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showCustomPicker) {
                ColorPicker("Pick a color", selection: $customColor)
                    .onChange(of: customColor) { _, newColor in
                        appState.updateNodeColor(nodeID, color: newColor.hexString)
                    }
                    .padding()
            }

            Divider()

            Text("Line Color")
                .font(.system(size: 12, weight: .semibold))

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(MindNode.presetColors, id: \.hex) { colorInfo in
                    lineColorButton(colorInfo.hex, colorInfo.name)
                }
            }
        }
        .padding(12)
        .frame(width: 200)
        .onAppear {
            if let color = Color(hex: node.backgroundColor) {
                customColor = color
            }
        }
    }

    private func colorButton(_ hex: String, _ label: String) -> some View {
        Button(action: { appState.updateNodeColor(nodeID, color: hex) }) {
            Circle()
                .fill(Color(hex: hex) ?? .gray)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(node.backgroundColor == hex ? Color.primary : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .help(label)
    }

    private func lineColorButton(_ hex: String, _ label: String) -> some View {
        Button(action: { appState.updateNodeLineColor(nodeID, color: hex) }) {
            Circle()
                .fill(Color(hex: hex) ?? .gray)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(node.lineColor == hex ? Color.primary : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .help(label)
    }
}
