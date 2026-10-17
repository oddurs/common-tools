import Testing

@testable import ShotKit

@Suite struct TextLayoutTests {
    /// One run per line of monospaced code, 0.01 wide per character and 0.04 tall per line.
    func code(_ lines: [String]) -> [TextRun] {
        lines.enumerated().compactMap { index, line in
            let indent = line.prefix { $0 == " " }.count
            let text = line.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { return nil }
            return TextRun(
                text: text, x: 0.1 + Double(indent) * 0.01, y: 0.9 - Double(index) * 0.04,
                width: Double(text.count) * 0.01, height: 0.03)
        }
    }

    @Test func codeKeepsItsIndentation() {
        let source = ["func f() {", "    if x {", "        return 1", "    }", "}"]
        #expect(TextLayout.text(from: code(source)) == source.joined(separator: "\n"))
    }

    @Test func linesComeTopToBottomWhateverOrderVisionGivesThem() {
        let source = ["first", "second", "third"]
        #expect(TextLayout.text(from: code(source).reversed()) == source.joined(separator: "\n"))
    }

    @Test func runsOnOneLineJoinLeftToRight() {
        let runs = [
            TextRun(text: "world", x: 0.5, y: 0.5, width: 0.1, height: 0.04),
            TextRun(text: "hello", x: 0.1, y: 0.505, width: 0.1, height: 0.04),
        ]
        #expect(TextLayout.text(from: runs) == "hello world")
    }

    @Test func memberAccessLosesTheSpaceVisionAdds() {
        #expect(TextLayout.joiningMembers("let size = preferences. imageSize") == "let size = preferences.imageSize")
        #expect(TextLayout.joiningMembers("foo(). bar. baz") == "foo().bar.baz")
        // A sentence ends before a capital, and an ellipsis isn't a member.
        #expect(TextLayout.joiningMembers("Done. Next step") == "Done. Next step")
        #expect(TextLayout.joiningMembers("wait ... then") == "wait ... then")
    }

    @Test func centredProseIsNotIndented() {
        // A large centred heading over a smaller subtitle, as on a web page.
        let runs = [
            TextRun(text: "Common Keys", x: 0.6, y: 0.5, width: 0.4, height: 0.1),
            TextRun(text: "Typed it on the wrong keyboard?", x: 0.5, y: 0.35, width: 0.45, height: 0.04),
        ]
        #expect(TextLayout.text(from: runs) == "Common Keys\nTyped it on the wrong keyboard?")
    }

    @Test func nothingRecognisedIsEmpty() {
        #expect(TextLayout.text(from: []) == "")
        #expect(TextLayout.text(from: [TextRun(text: "", x: 0, y: 0, width: 0, height: 0)]) == "")
    }
}
