import BarKit
import Testing

@Suite struct MenuCopyTests {
    /// Probe's menu as Accessibility read it on macOS 26, off-screen.
    let probe: [MenuNode] = [
        MenuNode(title: "Probe action", key: "P"),
        MenuNode(title: "Checked option", checked: true),
        .separator,
        MenuNode(title: "Disabled item", enabled: false),
        MenuNode(title: "More choices", children: [MenuNode(title: "Deep action")]),
    ]

    @Test func aMenuWithTitledItemsCanBeCopied() {
        #expect(MenuCopy.copyable(probe))
    }

    @Test func aMenuOfCustomViewsCant() {
        let views = [MenuNode(title: ""), MenuNode(title: ""), .separator]
        #expect(!MenuCopy.copyable(views))
        #expect(!MenuCopy.copyable([]))
    }

    @Test func customViewsAndStraySeparatorsAreLeftOut() {
        let nodes: [MenuNode] = [
            .separator, MenuNode(title: "A"), .separator, .separator, MenuNode(title: ""), MenuNode(title: "B"),
            .separator,
        ]
        let tidied = MenuCopy.tidy(nodes.enumerated().map { ($0.element, $0.offset) })
        #expect(tidied.map(\.node.title) == ["A", "", "B"])
        // Each keeps its index in the real menu, for finding it there again.
        #expect(tidied.map(\.index) == [1, 2, 5])
    }

    @Test func anItemIsFoundWhereItWas() {
        #expect(MenuPath.find((1, "Checked option"), in: ["Probe action", "Checked option", ""]) == 1)
    }

    @Test func anItemThatMovedIsFoundByTitle() {
        // The app rebuilt its menu with a new item at the top.
        #expect(MenuPath.find((1, "Checked option"), in: ["New", "Probe action", "Checked option"]) == 2)
    }

    @Test func anItemThatIsGoneIsntFound() {
        #expect(MenuPath.find((1, "Checked option"), in: ["Probe action"]) == nil)
    }
}
