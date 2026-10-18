import BarKit
import Testing

@Suite struct DividerLayoutTests {
    @Test func aDividerReachesJustPastTheScreensLeftEdge() {
        // Measured on Tahoe: the divider ends at 1136 on a screen starting at 0, and macOS
        // pads each item by 16 pt.
        let reach = DividerLayout.reach(dividerEnd: 1136, screenMinX: 0, padding: 16)
        #expect(reach == 1184)
        // The stretched item then starts 64 pt left of the screen, so every icon is off it.
        #expect(1136 - (reach + 16) == -64)
    }

    @Test func aDividerOnAScreenFurtherRightReachesFromThatScreensEdge() {
        #expect(DividerLayout.reach(dividerEnd: 2864, screenMinX: 1728, padding: 16) == 1184)
    }

    @Test func aStretchedDividerStartingPastTheScreensEdgeClearsIt() {
        #expect(DividerLayout.clearsScreen(windowMinX: -64, screenMinX: 0))
        #expect(DividerLayout.clearsScreen(windowMinX: 1664, screenMinX: 1728))
    }

    @Test func aStretchedDividerWhoseEndSlidRightNoLongerClearsTheScreen() {
        // Its reach was measured with its end at 600; it has since slid to 900, so the icons
        // left of it would sit from x 236 on, behind the app's menus.
        let reach = DividerLayout.reach(dividerEnd: 600, screenMinX: 0, padding: 16)
        #expect(!DividerLayout.clearsScreen(windowMinX: 900 - (reach + 16), screenMinX: 0))
        let again = DividerLayout.reach(dividerEnd: 900, screenMinX: 0, padding: 16)
        #expect(DividerLayout.clearsScreen(windowMinX: 900 - (again + 16), screenMinX: 0))
    }

    @Test func theReachNeverExceedsTheFullStretch() {
        #expect(DividerLayout.reach(dividerEnd: 20_000, screenMinX: 0, padding: 16) == DividerLayout.stretchedLength)
    }

    @Test func theDividerHidesOnlyLeftOfTheFolder() {
        #expect(ItemPositions(toggle: 0, divider: 1).dividerHides)
        // Stretched right of the folder, it would push the folder and the pinned icons off-screen.
        #expect(!ItemPositions(toggle: 1, divider: 0).dividerHides)
        #expect(!ItemPositions(toggle: 3, divider: 3).dividerHides)
    }
}

@Suite struct ItemPositionsTests {
    @Test func aFreshInstallStartsBesideTheSystemItemsInOrder() {
        #expect(ItemPositions.seeded(toggle: nil, divider: nil) == ItemPositions(toggle: 0, divider: 1))
    }

    @Test func savedPositionsAreKept() {
        #expect(ItemPositions.seeded(toggle: 40, divider: 90) == ItemPositions(toggle: 40, divider: 90))
    }

    @Test func aNewDividerStartsLeftOfWhereTheUserMovedTheFolder() {
        #expect(ItemPositions.seeded(toggle: 40, divider: nil) == ItemPositions(toggle: 40, divider: 41))
    }

    @Test func moreKeepsTheChevronsNameAndOtherFoldersGetTheirOwn() {
        #expect(ItemName.folder(FolderConfig.moreID) == "toggle")
        #expect(ItemName.folder("work") == "folder-work")
    }

    @Test func foldersSitAroundMoreWithoutMovingIt() {
        let positions = FolderPositions.positions(["a", "more", "b", "c"], more: 582)
        #expect(positions["more"] == 582)
        #expect(positions["a"]! > 582)
        #expect(positions["b"]! < 582 && positions["c"]! < positions["b"]!)
        // Within a point of More, so they stay together and right of the divider.
        #expect(positions.values.allSatisfy { abs($0 - 582) < 1 })
    }

    @Test func theDividerHidesOnlyLeftOfEveryFolder() {
        let positions = ItemPositions(toggle: 582, divider: 583)
        #expect(positions.dividerHides(folders: [582, 582.01, 581.99]))
        #expect(!positions.dividerHides(folders: [582, 583.5]))
    }

    @Test func autosaveNamesStayPut() {
        // Renaming either would lose every user's arrangement.
        #expect(ItemName.toggle == "toggle")
        #expect(ItemName.divider == "divider")
    }
}
