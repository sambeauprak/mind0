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
}
