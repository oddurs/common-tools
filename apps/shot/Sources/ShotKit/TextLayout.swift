/// A run of recognised text and where it sat, in an image's unit square with the origin at the bottom left,
/// as Vision reports it.
public struct TextRun: Equatable, Sendable {
    public let text: String
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(text: String, x: Double, y: Double, width: Double, height: Double) {
        self.text = text
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Puts recognised text back in reading order, with indentation, so a screenshot of code pastes as code.
public enum TextLayout {
    public static func text(from runs: [TextRun]) -> String {
        let runs = runs.filter { !$0.text.isEmpty && $0.width > 0 && $0.height > 0 }
        guard !runs.isEmpty else { return "" }

        // Runs whose vertical middles are within half a line of each other share a line.
        let lineHeight = median(runs.map(\.height))
        var lines: [[TextRun]] = []
        for run in runs.sorted(by: { $0.y + $0.height / 2 > $1.y + $1.height / 2 }) {
            let middle = run.y + run.height / 2
            if let last = lines.last?.first, abs(last.y + last.height / 2 - middle) < lineHeight / 2 {
                lines[lines.count - 1].append(run)
            } else {
                lines.append([run])
            }
        }

        // Indentation in characters, measured from the leftmost line with the text's own character width,
        // but only for monospaced text: in prose or a centred heading, an offset isn't an indent.
        let widths = runs.filter { $0.text.count >= 4 }.map { $0.width / Double($0.text.count) }
        let monospaced = (widths.min().map { (widths.max() ?? 0) / $0 } ?? .infinity) < 1.25
        let characterWidth = monospaced ? median(widths) : 0
        let left = runs.map(\.x).min() ?? 0
        return lines.map { line in
            let ordered = line.sorted { $0.x < $1.x }
            let indent = characterWidth > 0 ? Int(((ordered[0].x - left) / characterWidth).rounded()) : 0
            let text = ordered.map(\.text).joined(separator: " ")
            return String(repeating: " ", count: max(0, indent)) + (monospaced ? joiningMembers(text) : text)
        }
        .joined(separator: "\n")
    }

    /// Vision reads `preferences.imageSize` as `preferences. imageSize`. In code, a dot between a name and a
    /// lowercase letter is member access, never the end of a sentence, so the space goes.
    static func joiningMembers(_ line: String) -> String {
        line.replacing(/([A-Za-z0-9_)\]])\. ([a-z_])/) { "\($0.1).\($0.2)" }
    }

    static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        return sorted[sorted.count / 2]
    }
}
