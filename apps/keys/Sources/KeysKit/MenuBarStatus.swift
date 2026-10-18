/// What the menu bar item says about the front app: fixing, locked to one layout, or not fixing.
/// The shell draws `look` and shows `toolTip`; the rules live here so they can be tested.
public struct MenuBarStatus: Equatable, Sendable {
    public enum Look: Equatable, Sendable {
        /// Fixing words: the current layout's flag.
        case working
        /// The front app is pinned to the current layout: its flag with a lock beside it.
        case locked
        /// Not fixing anything: the flag dimmed, like a disabled menu item.
        case dimmed
    }

    /// A layout as the menu bar names it.
    public struct Layout: Equatable, Sendable {
        public var id: String
        public var flag: String
        public var name: String

        public init(id: String, flag: String, name: String) {
            self.id = id
            self.flag = flag
            self.name = name
        }
    }

    public let look: Look
    public let toolTip: String

    /// - Parameters:
    ///   - trusted: Accessibility access is granted.
    ///   - fixing: fixing is on (not paused from the menu).
    ///   - layout: the layout in use, if it is one Common Keys knows.
    ///   - app: the front app's name.
    ///   - paused: the user paused Common Keys in the front app.
    ///   - pinned: the layout the user pinned the front app to, if it is enabled.
    public init(trusted: Bool, fixing: Bool, layout: Layout?, app: String?, paused: Bool, pinned: Layout?) {
        // A pin the user has switched away from in this app would make the lock claim a layout
        // the flag beside it doesn't show.
        let locked = layout != nil && pinned?.id == layout?.id
        if !trusted || !fixing || layout == nil {
            look = .dimmed
        } else if locked {
            // A pin holds the layout even where words are left alone, so it outranks the pause.
            look = .locked
        } else if paused {
            look = .dimmed
        } else {
            look = .working
        }

        let place = app.map { " in \($0)" } ?? ""
        var parts: [String] = []
        if locked, let pinned {
            parts.append("Locked to \(pinned.flag) \(pinned.name)\(place)")
        } else if let layout {
            parts.append(layout.name)
        }
        if !trusted { parts.append("Needs Accessibility access") }
        if !fixing { parts.append("Fixing is paused") }
        if paused { parts.append(locked ? "Words left as typed" : "Paused\(place)") }
        if !locked, let pinned, let app { parts.append("\(app) is locked to \(pinned.flag) \(pinned.name)") }
        toolTip = parts.joined(separator: " · ")
    }
}
