import BarKit
import CoreGraphics
import Testing

@Suite struct DropdownTests {
    func owner(_ bundleID: String, _ name: String, label: String?) -> AccessibleItem {
        AccessibleItem(pid: 1, bundleID: bundleID, appName: name, frame: .zero, label: label)
    }

    // MARK: Status

    @Test func macOSItemsGiveTheirStateAfterTheirName() {
        // Recorded on macOS 26.
        let wifi = owner("com.apple.controlcenter", "Control Center", label: "Wi‑Fi, connected, 3 bars")
        #expect(Dropdown.status(of: wifi) == "connected, 3 bars")
    }

    @Test func aLabelThatIsOnlyANameHasNoStatus() {
        #expect(Dropdown.status(of: owner("com.apple.controlcenter", "Control Center", label: "Battery")) == nil)
        #expect(Dropdown.status(of: owner("com.apple.controlcenter", "Control Center", label: "Focus,")) == nil)
    }

    @Test func otherAppsLabelsArentReadAsStatus() {
        // Common Battery's label has a comma too, but it is the app's own, not macOS's.
        let battery = owner("com.oddurs.commonbattery", "Common Battery", label: "Battery 34%, 1:17 remaining")
        #expect(Dropdown.status(of: battery) == nil)
    }

    // MARK: Symbols

    @Test func macOSItemsGetTheirOwnSymbol() {
        #expect(Dropdown.symbol(identifier: "com.apple.menuextra.wifi", name: "Wi‑Fi") == "wifi")
        #expect(Dropdown.symbol(identifier: "com.apple.menuextra.now-playing", name: "Now Playing") == "play.circle")
        #expect(Dropdown.symbol(identifier: "com.apple.menuextra.battery", name: "Battery") == "battery.100percent")
        #expect(Dropdown.symbol(identifier: "com.apple.menuextra.focusmode", name: "Focus") == "moon")
    }

    @Test func anItemWithoutAnIdentifierGoesByName() {
        #expect(Dropdown.symbol(identifier: nil, name: "Siri") == "waveform")
        #expect(Dropdown.symbol(identifier: nil, name: "Search") == "magnifyingglass")
    }

    @Test func anUnknownItemHasNoSymbol() {
        #expect(Dropdown.symbol(identifier: nil, name: "U.S.") == nil)
        #expect(Dropdown.symbol(identifier: "com.example.thing", name: "Thing") == nil)
    }

    // MARK: Filtering

    @Test func typingMatchesAnywhereInTheNameOrStatus() {
        #expect(Dropdown.matches("drop", name: "Dropbox", status: nil))
        #expect(Dropdown.matches("box", name: "Dropbox", status: nil))
        #expect(Dropdown.matches("conn", name: "Wi‑Fi", status: "connected, 3 bars"))
        #expect(!Dropdown.matches("tele", name: "Dropbox", status: nil))
    }

    @Test func typingIgnoresCaseAccentsAndWordOrder() {
        #expect(Dropdown.matches("DROP", name: "Dropbox", status: nil))
        #expect(Dropdown.matches("creme", name: "Crème Menu", status: nil))
        #expect(Dropdown.matches("cloud creative", name: "Creative Cloud", status: nil))
    }

    @Test func anEmptyQueryMatchesEverything() {
        #expect(Dropdown.matches("", name: "Anything", status: nil))
    }

    // MARK: Keyboard

    @Test func theFirstArrowSelectsAnEnd() {
        var down = Dropdown.Selection()
        down.move(by: 1, count: 5)
        #expect(down.index == 0)
        var up = Dropdown.Selection()
        up.move(by: -1, count: 5)
        #expect(up.index == 4)
    }

    @Test func arrowsStopAtTheEnds() {
        var selection = Dropdown.Selection(index: 4)
        selection.move(by: 1, count: 5)
        #expect(selection.index == 4)
        selection = Dropdown.Selection(index: 0)
        selection.move(by: -1, count: 5)
        #expect(selection.index == 0)
    }

    @Test func filteringSelectsTheBestMatchSoReturnOpensIt() {
        var selection = Dropdown.Selection(index: 3)
        selection.settle(count: 2, filtering: true)
        #expect(selection.index == 0)
    }

    @Test func aShorterListKeepsThePlaceInsideIt() {
        var selection = Dropdown.Selection(index: 3)
        selection.settle(count: 2, filtering: false)
        #expect(selection.index == 1)
        selection.settle(count: 0, filtering: false)
        #expect(selection.index == nil)
        var none = Dropdown.Selection()
        none.move(by: 1, count: 0)
        #expect(none.index == nil)
    }
}
