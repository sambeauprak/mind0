import Foundation

struct MarkdownExporter {
    static func export(doc: MindDocument, to directoryURL: URL) {
        for (nodeID, node) in doc.nodes {
            let safeName = node.title
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let fileName = "\(safeName).md"
            let fileURL = directoryURL.appendingPathComponent(fileName)

            var md = "# \(node.title)\n\n"

            if node.isRoot {
                md += "*Root Node*\n\n"
            }

            if !node.childrenIDs.isEmpty {
                md += "## Children\n\n"
                for childID in node.childrenIDs {
                    if let child = doc.nodes[childID] {
                        md += "- [\(child.title)](\(child.title.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")).md)\n"
                    }
                }
                md += "\n"
            }

            if let parentID = findParent(of: nodeID, in: doc) {
                if let parent = doc.nodes[parentID] {
                    md += "**Parent:** [\(parent.title)](\(parent.title.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")).md)\n\n"
                }
            }

            md += "---\n"
            md += "*Exported from Mind0*\n"

            try? md.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    private static func findParent(of nodeID: UUID, in doc: MindDocument) -> UUID? {
        for (id, node) in doc.nodes {
            if node.childrenIDs.contains(nodeID) {
                return id
            }
        }
        return nil
    }
}
