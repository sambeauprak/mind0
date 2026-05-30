import SwiftUI

struct Theme: Identifiable, Codable {
    let id: UUID
    var name: String
    var nodeShape: NodeShape
    var lineColor: String
    var canvasBackgroundColor: String
    var nodeBackgroundColor: String
    var imageCoverMode: Bool
    var nodeTextColor: String

    init(
        id: UUID = UUID(),
        name: String = "Default",
        nodeShape: NodeShape = .roundedRect,
        lineColor: String = "#4A90D9",
        canvasBackgroundColor: String = "#F5F5F5",
        nodeBackgroundColor: String = "#FFFFFF",
        imageCoverMode: Bool = false,
        nodeTextColor: String = "#333333"
    ) {
        self.id = id
        self.name = name
        self.nodeShape = nodeShape
        self.lineColor = lineColor
        self.canvasBackgroundColor = canvasBackgroundColor
        self.nodeBackgroundColor = nodeBackgroundColor
        self.imageCoverMode = imageCoverMode
        self.nodeTextColor = nodeTextColor
    }

    static let presets: [Theme] = [
        Theme(name: "Default", nodeShape: .roundedRect),
        Theme(name: "Nature", nodeShape: .roundedRect, lineColor: "#27AE60", canvasBackgroundColor: "#E8F5E9", nodeBackgroundColor: "#FFFFFF", imageCoverMode: false),
        Theme(name: "Ocean", nodeShape: .capsule, lineColor: "#2980B9", canvasBackgroundColor: "#E3F2FD", nodeBackgroundColor: "#FFFFFF", imageCoverMode: false),
        Theme(name: "Sunset", nodeShape: .ellipse, lineColor: "#E67E22", canvasBackgroundColor: "#FFF3E0", nodeBackgroundColor: "#FFF8E1", imageCoverMode: false),
        Theme(name: "Midnight", nodeShape: .roundedRect, lineColor: "#8E44AD", canvasBackgroundColor: "#1A1A2E", nodeBackgroundColor: "#16213E", imageCoverMode: false, nodeTextColor: "#FFFFFF"),
        Theme(name: "Trello Covers", nodeShape: .roundedRect, lineColor: "#5BA4CF", canvasBackgroundColor: "#F5F5F5", nodeBackgroundColor: "#FFFFFF", imageCoverMode: true),
        Theme(name: "Minimal", nodeShape: .rectangle, lineColor: "#95A5A6", canvasBackgroundColor: "#FFFFFF", nodeBackgroundColor: "#FAFAFA", imageCoverMode: false),
        Theme(name: "Vibrant", nodeShape: .roundedRect, lineColor: "#E74C3C", canvasBackgroundColor: "#1A1A2E", nodeBackgroundColor: "#E74C3C", imageCoverMode: false, nodeTextColor: "#FFFFFF"),
    ]
}
