import BarKit
import CoreGraphics
import Testing

/// Recorded on a 14-inch MacBook Pro on macOS 26.5 with an earlier Common Bar showing its hidden icons: a 1728-point-wide
/// screen, the notch from x 771 to 956, a 33-point menu bar, and every status item's window
/// belonging to Control Center (pid 628). Names are what Screen Recording shows; Common Bar
/// never sees them.
@Suite struct MenuBarModelTests {
    static let controlCenter: Int32 = 628

    static func w(_ id: UInt32, _ minX: CGFloat, _ maxX: CGFloat, y: CGFloat = 0, h: CGFloat = 33) -> StatusItemWindow {
        StatusItemWindow(
            id: id, frame: CGRect(x: minX, y: y, width: maxX - minX, height: h), ownerPID: controlCenter,
            ownerName: "Control Center")
    }

    static let notched = MenuBarGeometry(minX: 0, maxX: 1728, top: 0, height: 33, notch: 771...956)

    static let revealed: [StatusItemWindow] = [
        w(55267, 471, 509),  // command
        w(51914, 471, 471, h: 0),  // a zero-size window Control Center keeps
        w(55741, 509, 547),  // shot
        w(27083, 547, 585),
        w(42813, 585, 617),
        w(124, 617, 657),
        w(583, 657, 697),
        w(45913, 697, 733),
        w(46, 733, 769),
        w(40, 769, 801),
        w(36, 801, 832),  // Siri
        w(36720, 832, 864),
        w(37, 864, 908),
        w(19, 908, 946),  // WiFi
        w(17, 946, 988),  // Battery
        w(52716, 948, 1284, y: 29, h: 167),  // a panel open below the bar
        w(8088, 988, 1021),  // NowPlaying
        w(55696, 1021, 1052),  // a Common Glyph
        w(55742, 1052, 1082),  // Common Keys
        w(55260, 1082, 1083),  // Common Bar's divider, taken down to nothing
        w(55261, 1083, 1084),  // its always-hidden divider
        w(55256, 1084, 1110),  // its chevron
        w(55778, 1110, 1160),  // Common Battery
        w(55478, 1160, 1464),  // Common Stats
        w(55692, 1464, 1502),  // a Common Glyph
        w(55847, 1502, 1540),  // Focus
        w(20, 1540, 1582),  // Control Center
        w(18, 1582, 1730),  // the clock, a little past the edge
    ]

    static let ownRevealed = OwnItems(
        divider: CGRect(x: 1082, y: 0, width: 1, height: 33),
        others: [CGRect(x: 1083, y: 0, width: 1, height: 33), CGRect(x: 1084, y: 0, width: 26, height: 33)])

    let model = MenuBarModel(windows: revealed, geometry: notched, own: ownRevealed)

    func ids(_ items: [MenuBarItem]) -> [UInt32] { items.map(\.id) }

    @Test func listsEveryOtherAppsIconLeftToRight() {
        // 27 windows, less the zero-size one, the panel, and Common Bar's three.
        #expect(model.items.count == 23)
        #expect(model.items.first?.id == 55267)
        #expect(model.items.last?.id == 18)
        #expect(model.items.map(\.window.frame.minX) == model.items.map(\.window.frame.minX).sorted())
    }

    @Test func leavesOutCommonBarsOwnItemsByWhereTheyAre() {
        #expect(!ids(model.items).contains(55260))
        #expect(!ids(model.items).contains(55261))
        #expect(!ids(model.items).contains(55256))
    }

    @Test func leavesOutPanelsAndEmptyWindowsOnTheStatusLayer() {
        #expect(!ids(model.items).contains(52716))
        #expect(!ids(model.items).contains(51914))
    }

    @Test func iconsLeftOfTheDividerAreHidden() {
        let hidden = model.items.filter { $0.section == .hidden }
        #expect(hidden.count == 17)
        #expect(ids(model.items.filter { $0.section == .shown }) == [55778, 55478, 55692, 55847, 20, 18])
    }

    @Test func onThisMacOnlyThreeRevealedIconsCanBeSeen() {
        let seen = model.items.filter { $0.section == .hidden && $0.visibility == .visible }
        #expect(ids(seen) == [8088, 55696, 55742])
    }

    @Test func iconsTouchingTheNotchAreUnderIt() {
        let under = ids(model.items.filter { $0.visibility == .underNotch })
        // From the one straddling its left edge to Battery, which is 10 points into it.
        #expect(under == [40, 36, 36720, 37, 19, 17])
    }

    @Test func iconsLeftOfTheNotchAreBehindTheAppsMenus() {
        let behind = ids(model.items.filter { $0.visibility == .behindAppMenus })
        #expect(behind == [55267, 55741, 27083, 42813, 124, 583, 45913, 46])
    }

    @Test func fourteenIconsAreStranded() {
        let stranded = model.items.filter(\.visibility.isStranded)
        #expect(stranded.count == 14)
        #expect(stranded.allSatisfy { $0.section == .hidden })
    }

    @Test func everyIconRightOfTheChevronCanBeSeen() {
        #expect(model.items.filter { $0.section == .shown }.allSatisfy { $0.visibility == .visible })
    }

    // MARK: Collapsed

    /// The same bar collapsed: the divider stretched until its window starts 64 points past the
    /// screen's edge, and the hidden icons beyond it, where the window server still lists them.
    static let collapsed: [StatusItemWindow] = [
        w(55267, -675, -637),
        w(55742, -94, -64),
        w(55260, -64, 1082),
        w(55256, 1084, 1110),
        w(55778, 1110, 1160),
        w(18, 1582, 1730),
    ]

    static let ownCollapsed = OwnItems(
        divider: CGRect(x: -64, y: 0, width: 1146, height: 33),
        others: [CGRect(x: 1084, y: 0, width: 26, height: 33)])

    let collapsedModel = MenuBarModel(windows: collapsed, geometry: notched, own: ownCollapsed)

    @Test func hiddenIconsPastTheEdgeAreOffScreenNotStranded() {
        let hidden = collapsedModel.items.filter { $0.section == .hidden }
        #expect(ids(hidden) == [55267, 55742])
        #expect(hidden.allSatisfy { $0.visibility == .offScreen })
        #expect(collapsedModel.items.allSatisfy { !$0.visibility.isStranded })
    }

    // MARK: Other screens

    @Test func withoutANotchTheWholeBarCanShowIcons() {
        let plain = MenuBarGeometry(minX: 0, maxX: 1920, height: 24)
        #expect(plain.visibility(of: CGRect(x: 10, y: 0, width: 30, height: 24)) == .visible)
        #expect(plain.visibility(of: CGRect(x: -20, y: 0, width: 30, height: 24)) == .behindAppMenus)
        #expect(plain.visibility(of: CGRect(x: -40, y: 0, width: 30, height: 24)) == .offScreen)
    }

    @Test func aScreenToTheRightCountsFromItsOwnEdge() {
        let right = MenuBarGeometry(minX: 1728, maxX: 3648, top: -200, height: 24)
        let window = StatusItemWindow(
            id: 1, frame: CGRect(x: 1700, y: -200, width: 30, height: 24), ownerPID: 1, ownerName: "")
        let model = MenuBarModel(windows: [window], geometry: right, own: OwnItems(divider: nil))
        #expect(model.items.map(\.visibility) == [.behindAppMenus])
    }

    @Test func iconsInAnotherScreensBarAreLeftOut() {
        let other = StatusItemWindow(
            id: 2, frame: CGRect(x: 1000, y: -200, width: 30, height: 24), ownerPID: 1, ownerName: "")
        #expect(MenuBarModel(windows: [other], geometry: Self.notched, own: OwnItems(divider: nil)).items.isEmpty)
    }

    @Test func menusAndPopoversHangFromTheBar() {
        // Recorded: a menu at y 34, a popover with its arrow at y 28, Control Center's panel at 29.
        #expect(Self.notched.hangsBelow(CGRect(x: 600, y: 34, width: 57, height: 34)))
        #expect(Self.notched.hangsBelow(CGRect(x: 0, y: 28, width: 226, height: 106)))
        #expect(Self.notched.hangsBelow(CGRect(x: 948, y: 29, width: 336, height: 167)))
    }

    @Test func aWindowLowerDownOrOffThisScreenDoesNot() {
        #expect(!Self.notched.hangsBelow(CGRect(x: 100, y: 200, width: 600, height: 400)))
        #expect(!Self.notched.hangsBelow(CGRect(x: 0, y: 0, width: 1728, height: 33)))
        #expect(!Self.notched.hangsBelow(CGRect(x: -7604, y: 34, width: 57, height: 34)))
    }

    @Test func withoutTheDividerLaidOutNothingIsCountedHidden() {
        let model = MenuBarModel(windows: Self.revealed, geometry: Self.notched, own: OwnItems(divider: nil))
        #expect(model.items.allSatisfy { $0.section == .shown })
    }
}
