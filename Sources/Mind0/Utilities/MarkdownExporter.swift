import Foundation

struct MarkdownExporter {
    static func export(doc: MindDocument, to url: URL) {
        guard let root = doc.nodes[doc.rootNodeID] else { return }

        var md = "# \(root.title)\n\n"

        func appendChildren(of nodeID: UUID, level: Int) {
            guard let node = doc.nodes[nodeID] else { return }
            for childID in node.childrenIDs {
                guard let child = doc.nodes[childID] else { continue }
                let heading = String(repeating: "#", count: level + 1)
                md += "\(heading) \(child.title)\n\n"
                if !child.childrenIDs.isEmpty {
                    appendChildren(of: childID, level: level + 1)
                }
            }
        }

        appendChildren(of: doc.rootNodeID, level: 1)

        try? md.write(to: url, atomically: true, encoding: .utf8)
    }
}
