import Foundation
import SwiftUI

enum NodeShape: String, Codable, CaseIterable {
    case roundedRect
    case ellipse
    case capsule
    case rectangle

    var displayName: String {
        switch self {
        case .roundedRect: "Rounded Rectangle"
        case .ellipse: "Ellipse"
        case .capsule: "Capsule"
        case .rectangle: "Rectangle"
        }
    }
}

struct MindNode: Identifiable, Codable {
    let id: UUID
    var title: String
    var childrenIDs: [UUID]
    var isCollapsed: Bool
    var position: CGPoint
    var backgroundColor: String
    var imageData: Data?
    var imagePath: String?
    var shape: NodeShape
    var lineColor: String
    var imageCoverMode: Bool
    var isRoot: Bool
    var columnIndex: Int
    var childrenLayout: LayoutType?

    init(
        id: UUID = UUID(),
        title: String = "New Node",
        childrenIDs: [UUID] = [],
        isCollapsed: Bool = false,
        position: CGPoint = .zero,
        backgroundColor: String = "#FFFFFF",
        imageData: Data? = nil,
        imagePath: String? = nil,
        shape: NodeShape = .roundedRect,
        lineColor: String = "#4A90D9",
        imageCoverMode: Bool = true,
        isRoot: Bool = false,
        columnIndex: Int = 0,
        childrenLayout: LayoutType? = nil
    ) {
        self.id = id
        self.title = title
        self.childrenIDs = childrenIDs
        self.isCollapsed = isCollapsed
        self.position = position
        self.backgroundColor = backgroundColor
        self.imageData = imageData
        self.imagePath = imagePath
        self.shape = shape
        self.lineColor = lineColor
        self.imageCoverMode = imageCoverMode
        self.isRoot = isRoot
        self.columnIndex = columnIndex
        self.childrenLayout = childrenLayout
    }

    var backgroundColorSwift: Color {
        Color(hex: backgroundColor) ?? .white
    }

    var lineColorSwift: Color {
        Color(hex: lineColor) ?? .blue
    }

    func swiftUIImage(availableImages: [String: NSImage]) -> NSImage? {
        if let data = imageData, let img = NSImage(data: data) {
            return img
        }
        if let path = imagePath, let img = availableImages[path] {
            return img
        }
        return nil
    }

    static let presetColors: [(name: String, hex: String, pastel: String)] = [
        ("Red", "#E74C3C", "#FFADAD"),
        ("Orange", "#F39C12", "#FFD6A5"),
        ("Yellow", "#F1C40F", "#FDFFB6"),
        ("Green", "#2ECC71", "#CAFFBF"),
        ("Teal", "#1ABC9C", "#A0E7E5"),
        ("Blue", "#3498DB", "#B5E2FA"),
        ("Purple", "#9B59B6", "#CDB4DB"),
        ("Pink", "#E91E63", "#FFC8DD"),
    ]
}

struct AnyShape: Shape {
    private let makePath: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        makePath = { @Sendable rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        makePath(rect)
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        switch hex.count {
        case 6:
            self.init(
                red: Double((int >> 16) & 0xFF) / 255,
                green: Double((int >> 8) & 0xFF) / 255,
                blue: Double(int & 0xFF) / 255,
                opacity: 1
            )
        case 8:
            self.init(
                red: Double((int >> 16) & 0xFF) / 255,
                green: Double((int >> 8) & 0xFF) / 255,
                blue: Double(int & 0xFF) / 255,
                opacity: Double((int >> 24) & 0xFF) / 255
            )
        default: return nil
        }
    }

    var hexString: String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else { return "#000000" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
