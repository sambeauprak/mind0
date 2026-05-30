import Foundation
import AppKit

struct SVGExporter {
    static func export(doc: MindDocument) -> String {
        let allNodes = doc.flattenedNodes()
        let padding: CGFloat = 40
        let cardW: CGFloat = 180
        let cardH: CGFloat = 80

        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity

        for (_, node) in allNodes {
            minX = min(minX, node.position.x - cardW / 2)
            minY = min(minY, node.position.y - cardH / 2)
            maxX = max(maxX, node.position.x + cardW / 2)
            maxY = max(maxY, node.position.y + cardH / 2)
        }

        let width = maxX - minX + padding * 2
        let height = maxY - minY + padding * 2
        let offsetX = -minX + padding
        let offsetY = -minY + padding

        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(width) \(height)">
        <rect width="\(width)" height="\(height)" fill="#F5F5F5" rx="4"/>

        """

        for (_, parent) in doc.nodes {
            for childID in parent.childrenIDs {
                guard let child = doc.nodes[childID] else { continue }
                let px = parent.position.x + offsetX
                let py = parent.position.y + offsetY
                let cx = child.position.x + offsetX
                let cy = child.position.y + offsetY
                let c1x = px + (cx - px) * 0.5
                let c1y = py + (cy - py) * 0.3
                let c2x = cx - (cx - px) * 0.5
                let c2y = cy - (cy - py) * 0.3

                svg += """
                  <path d="M \(px) \(py) C \(c1x) \(c1y), \(c2x) \(c2y), \(cx) \(cy)"
                        fill="none" stroke="\(parent.lineColor)" stroke-width="2" stroke-linecap="round"/>\n
                """
            }
        }

        for (_, node) in allNodes {
            let x = node.position.x + offsetX - cardW / 2
            let y = node.position.y + offsetY - cardH / 2
            let rx: CGFloat = node.shape == .roundedRect || node.shape == .capsule ? 8 : 0
            let ry: CGFloat = node.shape == .capsule ? cardH / 2 : (node.shape == .ellipse ? cardH / 2 : rx)

            svg += """
              <rect x="\(x)" y="\(y)" width="\(cardW)" height="\(cardH)" rx="\(rx)" ry="\(ry)"
                    fill="\(node.backgroundColor)" stroke="\(node.lineColor)" stroke-width="1.5"/>\n
            """

            if let imgData = node.imageData, NSImage(data: imgData) != nil {
                if node.imageCoverMode {
                    svg += """
                      <clipPath id="clip-\(node.id.uuidString)">
                        <rect x="\(x)" y="\(y)" width="\(cardW)" height="\(cardH)" rx="\(rx)" ry="\(ry)"/>
                      </clipPath>
                      <image href="data:image/png;base64,\(imgData.base64EncodedString())"
                             x="\(x)" y="\(y)" width="\(cardW)" height="\(cardH)"
                             clip-path="url(#clip-\(node.id.uuidString))"
                             preserveAspectRatio="xMidYMid slice"/>

                      <rect x="\(x)" y="\(y + cardH * 0.5)" width="\(cardW)" height="\(cardH * 0.5)"
                            fill="url(#grad-\(node.id.uuidString))" opacity="0.6"/>

                      <defs>
                        <linearGradient id="grad-\(node.id.uuidString)" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="0%" stop-color="transparent"/>
                          <stop offset="100%" stop-color="black"/>
                        </linearGradient>
                      </defs>
                    """
                } else {
                    let imgH: CGFloat = 40
                    svg += """
                      <clipPath id="clip-\(node.id.uuidString)">
                        <rect x="\(x + 4)" y="\(y + 4)" width="\(cardW - 8)" height="\(imgH)" rx="4"/>
                      </clipPath>
                      <image href="data:image/png;base64,\(imgData.base64EncodedString())"
                             x="\(x + 4)" y="\(y + 4)" width="\(cardW - 8)" height="\(imgH)"
                             clip-path="url(#clip-\(node.id.uuidString))"
                             preserveAspectRatio="xMidYMid slice"/>

                    """
                }
            }

            let textY = y + (node.imageCoverMode && node.imageData != nil ? cardH - 20 : cardH / 2 + 4)
            let safeTitle = node.title
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")

            let textColor = node.imageCoverMode && node.imageData != nil ? "#FFFFFF" : "#333333"

            svg += """
              <text x="\(x + cardW / 2)" y="\(textY)" text-anchor="middle"
                    font-family="-apple-system, sans-serif" font-size="12" font-weight="500"
                    fill="\(textColor)">\(safeTitle)</text>\n
            """
        }

        svg += "</svg>"
        return svg
    }
}
