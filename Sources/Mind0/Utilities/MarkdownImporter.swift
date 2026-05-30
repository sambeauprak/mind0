import Foundation

struct MarkdownImporter {
    static func `import`(from url: URL) -> MindDocument? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }

        let lines = text.components(separatedBy: .newlines)
        var stack: [(level: Int, id: UUID)] = []
        var nodes: [UUID: MindNode] = [:]
        var rootNodeID: UUID?

        let headingRegex = try? NSRegularExpression(pattern: "^(#{1,6})\\s+(.+)$")

        for line in lines {
            guard let regex = headingRegex,
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  let levelRange = Range(match.range(at: 1), in: line),
                  let titleRange = Range(match.range(at: 2), in: line)
            else { continue }

            let level = line[levelRange].count
            let title = String(line[titleRange]).trimmingCharacters(in: .whitespaces)

            let node = MindNode(title: title)
            nodes[node.id] = node

            if level == 1 {
                rootNodeID = node.id
                stack = [(level, node.id)]
            } else {
                while let top = stack.last, top.level >= level {
                    stack.removeLast()
                }
                if let parentID = stack.last?.id {
                    nodes[parentID]?.childrenIDs.append(node.id)
                }
                stack.append((level, node.id))
            }
        }

        guard let rootID = rootNodeID else { return nil }

        let doc = MindDocument(
            nodes: nodes,
            rootNodeID: rootID,
            layoutType: .tree
        )
        return doc
    }
}
