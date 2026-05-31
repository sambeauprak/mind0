import Foundation
import AppKit

struct SVGExporter {
    static func export(doc: MindDocument, availableImages: [String: NSImage] = [:]) -> String {
        let allNodes = doc.nodes.map { ($0.key, $0.value) }
        let padding: CGFloat = 40
        let cardW: CGFloat = 180
        let cardH: CGFloat = 80
        let coverCardH: CGFloat = 120
        let cornerR: CGFloat = 20

        func nodeHeight(_ node: MindNode) -> CGFloat {
            node.imageCoverMode && loadedImage(node) != nil ? coverCardH : cardH
        }

        func loadedImage(_ node: MindNode) -> NSImage? {
            if let data = node.imageData, let img = NSImage(data: data) { return img }
            if let path = node.imagePath, let img = availableImages[path] { return img }
            return nil
        }

        func imgBase64(_ node: MindNode) -> String? {
            let img: NSImage? = {
                if let data = node.imageData { return NSImage(data: data) }
                if let path = node.imagePath { return availableImages[path] }
                return nil
            }()
            guard let image = img,
                  let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else { return nil }
            return png.base64EncodedString()
        }

        func textColorForHex(_ hex: String) -> String {
            let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            guard h.count >= 6, let val = UInt64(h.prefix(6), radix: 16) else { return "#333333" }
            let r = CGFloat((val >> 16) & 0xFF) / 255
            let g = CGFloat((val >> 8) & 0xFF) / 255
            let b = CGFloat(val & 0xFF) / 255
            let lum = 0.299 * r + 0.587 * g + 0.114 * b
            return lum > 0.6 ? "#333333" : "#FFFFFF"
        }

        func safeXML(_ s: String) -> String {
            s.replacingOccurrences(of: "&", with: "&amp;")
             .replacingOccurrences(of: "<", with: "&lt;")
             .replacingOccurrences(of: ">", with: "&gt;")
             .replacingOccurrences(of: "\"", with: "&quot;")
        }

        func fmt(_ v: CGFloat) -> String { String(format: "%.1f", v) }

        func orthogonalPath(from: CGPoint, to: CGPoint) -> String {
            let midX = (from.x + to.x) / 2
            let hDist = abs(midX - from.x)
            let vDist = abs(to.y - from.y)

            guard vDist > 1 else {
                return "M \(fmt(from.x)) \(fmt(from.y)) L \(fmt(to.x)) \(fmt(to.y))"
            }

            let r = min(cornerR, hDist, vDist / 2)
            let dy: CGFloat = to.y >= from.y ? 1 : -1

            if to.x >= from.x {
                return "M \(fmt(from.x)) \(fmt(from.y))"
                    + " L \(fmt(midX - r)) \(fmt(from.y))"
                    + " Q \(fmt(midX)) \(fmt(from.y)) \(fmt(midX)) \(fmt(from.y + dy * r))"
                    + " L \(fmt(midX)) \(fmt(to.y - dy * r))"
                    + " Q \(fmt(midX)) \(fmt(to.y)) \(fmt(to.x)) \(fmt(to.y))"
            } else {
                return "M \(fmt(from.x)) \(fmt(from.y))"
                    + " L \(fmt(midX + r)) \(fmt(from.y))"
                    + " Q \(fmt(midX)) \(fmt(from.y)) \(fmt(midX)) \(fmt(from.y + dy * r))"
                    + " L \(fmt(midX)) \(fmt(to.y - dy * r))"
                    + " Q \(fmt(midX)) \(fmt(to.y)) \(fmt(to.x)) \(fmt(to.y))"
            }
        }

        // --- bounding box ---
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity

        for (_, node) in allNodes {
            let h = nodeHeight(node)
            minX = min(minX, node.position.x - cardW / 2)
            minY = min(minY, node.position.y - h / 2)
            maxX = max(maxX, node.position.x + cardW / 2)
            maxY = max(maxY, node.position.y + h / 2)
        }

        let width = maxX - minX + padding * 2
        let height = maxY - minY + padding * 2
        let ox = -minX + padding
        let oy = -minY + padding

        // --- collect gradient defs ---
        var gradientDefs = ""

        for (_, node) in allNodes {
            if loadedImage(node) != nil && node.imageCoverMode {
                gradientDefs += """
                  <linearGradient id="grad-\(node.id.uuidString)" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="transparent"/>
                    <stop offset="100%" stop-color="black"/>
                  </linearGradient>\n
                """
            }
        }

        // --- shadow filter ---
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(fmt(width)) \(fmt(height))">
        <defs>
          <filter id="card-shadow" x="-10%" y="-10%" width="130%" height="130%">
            <feDropShadow dx="0" dy="2" stdDeviation="4" flood-opacity="0.08"/>
          </filter>
        \(gradientDefs)</defs>
        <rect width="\(fmt(width))" height="\(fmt(height))" fill="#F5F5F5" rx="4"/>

        """

        // --- connections ---
        for (_, parent) in doc.nodes {
            for childID in parent.childrenIDs {
                guard let child = doc.nodes[childID] else { continue }
                let from = CGPoint(x: parent.position.x + ox, y: parent.position.y + oy)
                let to = CGPoint(x: child.position.x + ox, y: child.position.y + oy)
                svg += """
                  <path d="\(orthogonalPath(from: from, to: to))"
                        fill="none" stroke="\(parent.lineColor)" stroke-width="2" stroke-linecap="round"/>\n
                """
            }
        }

        // --- nodes ---
        for (_, node) in allNodes {
            let hasImage = loadedImage(node) != nil
            let h = nodeHeight(node)
            let x = node.position.x + ox - cardW / 2
            let y = node.position.y + oy - h / 2

            var rx: CGFloat
            var ry: CGFloat
            switch node.shape {
            case .roundedRect:
                rx = 8; ry = 8
            case .ellipse:
                rx = cardW / 2; ry = h / 2
            case .capsule:
                rx = h / 2; ry = h / 2
            case .rectangle:
                rx = 0; ry = 0
            }

            // card background + shadow
            svg += """
              <rect x="\(fmt(x))" y="\(fmt(y))" width="\(fmt(cardW))" height="\(fmt(h))"
                    rx="\(fmt(rx))" ry="\(fmt(ry))"
                    fill="\(node.backgroundColor)" stroke="\(node.lineColor)" stroke-width="1.5"
                    filter="url(#card-shadow)"/>\n
            """

            // image
            if let b64 = imgBase64(node) {
                let clipID = "clip-\(node.id.uuidString)"
                if node.imageCoverMode {
                    svg += """
                      <clipPath id="\(clipID)">
                        <rect x="\(fmt(x))" y="\(fmt(y))" width="\(fmt(cardW))" height="\(fmt(h))"
                              rx="\(fmt(rx))" ry="\(fmt(ry))"/>
                      </clipPath>
                      <image href="data:image/png;base64,\(b64)"
                             x="\(fmt(x))" y="\(fmt(y))" width="\(fmt(cardW))" height="\(fmt(h))"
                             clip-path="url(#\(clipID))"
                             preserveAspectRatio="xMidYMid slice"/>
                      <rect x="\(fmt(x))" y="\(fmt(y + h * 0.5))" width="\(fmt(cardW))" height="\(fmt(h * 0.5))"
                            fill="url(#grad-\(node.id.uuidString))" opacity="0.6"/>
                    """
                } else {
                    let imgH: CGFloat = 48
                    svg += """
                      <clipPath id="\(clipID)">
                        <rect x="\(fmt(x + 4))" y="\(fmt(y + 4))" width="\(fmt(cardW - 8))" height="\(fmt(imgH))" rx="4"/>
                      </clipPath>
                      <image href="data:image/png;base64,\(b64)"
                             x="\(fmt(x + 4))" y="\(fmt(y + 4))" width="\(fmt(cardW - 8))" height="\(fmt(imgH))"
                             clip-path="url(#\(clipID))"
                             preserveAspectRatio="xMidYMid slice"/>
                    """
                }
            }

            // text
            let textColor: String
            let textAnchor: String
            let textX: CGFloat
            let textY: CGFloat

            if hasImage && node.imageCoverMode {
                textColor = "#FFFFFF"
                textAnchor = "start"
                textX = x + 10
                textY = y + h - 10
            } else {
                textColor = textColorForHex(node.backgroundColor)
                textAnchor = "middle"
                textX = x + cardW / 2
                textY = y + h / 2 + 4
            }

            svg += """
              <text x="\(fmt(textX))" y="\(fmt(textY))" text-anchor="\(textAnchor)"
                    font-family="-apple-system, sans-serif" font-size="12" font-weight="500"
                    fill="\(textColor)">\(safeXML(node.title))</text>\n
            """
        }

        svg += "</svg>"
        return svg
    }
}
