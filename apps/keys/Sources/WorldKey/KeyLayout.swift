import Carbon
import Foundation

/// A keyboard layout's key table, read with the system's own translator, so every layout macOS
/// ships or the user installs works the same way: 251 of them across 35 scripts on macOS 26.
public struct KeyLayout: Sendable {
    private let data: Data
    private let reverse: ReverseTable

    public init(data: Data) {
        self.data = data
        self.reverse = ReverseTable()
    }

    /// The characters the keys type, dead keys composed.
    public func characters(for strokes: [KeyStroke]) -> String {
        withLayout { layout in
            var deadKeys: UInt32 = 0
            var text = ""
            var lastTyped = ""
            for stroke in strokes {
                lastTyped = Self.translate(layout, stroke.keyCode, stroke.modifiers, &deadKeys)
                text += lastTyped
            }
            // A dangling dead key sits on screen as its bare accent until the next key. Layouts that
            // type a character and keep state for what may stack on it, like Tibetan, show nothing more.
            if deadKeys != 0, lastTyped.isEmpty {
                text += Self.translate(layout, 49, 0, &deadKeys).replacingOccurrences(of: " ", with: "")
            }
            return text
        }
    }

    /// The keys that type `text` on this layout, preferring single keys over dead-key pairs and
    /// plain keys over modified ones. Nil when some part of `text` is not on the layout.
    ///
    /// A walk over the layout's dead-key states: from each state, a table says which keys type
    /// which output and the state they leave. Most layouts never leave the plain state. Syllabaries
    /// like Ge'ez type a consonant as a dead key and release it on the key after, so a word's keys
    /// run through several states, and which keys type one syllable depends on the next; the walk
    /// backtracks when a choice leaves no way to type the rest, and ends only in a state that
    /// shows nothing more, so a pending key never leaks into what follows the word.
    public func strokes(for text: String) -> [KeyStroke]? {
        let target = Array(text.unicodeScalars)
        var failed: Set<[UInt32]> = []

        func walk(_ index: Int, _ state: UInt32) -> [KeyStroke]? {
            if index == target.count { return isClean(state) ? [] : nil }
            let key: [UInt32] = [UInt32(index), state]
            guard !failed.contains(key) else { return nil }
            let table = self.table(from: state)
            // Longest match first: one key can type several code points, as in Indic layouts.
            for length in stride(from: min(table.longest, target.count - index), through: 1, by: -1) {
                var piece = String.UnicodeScalarView()
                piece.append(contentsOf: target[index..<index + length])
                for entry in table.entries[String(piece)] ?? [] {
                    if let rest = walk(index + length, entry.state) { return entry.strokes + rest }
                }
            }
            failed.insert(key)
            return nil
        }
        return walk(0, 0)
    }

    /// Whether a word can end in `state`: the space after it types what a space types from the
    /// plain state (a space, or on Tibetan a tsheg). A pending dead key would type its bare accent
    /// first, or on Ge'ez the consonant it holds.
    private func isClean(_ state: UInt32) -> Bool {
        reverse.clean(state) {
            withLayout { layout in
                var plain: UInt32 = 0
                var next = state
                return Self.translate(layout, 49, 0, &next) == Self.translate(layout, 49, 0, &plain)
            }
        }
    }

    private func table(from state: UInt32) -> ReverseTable.Table {
        if let known = reverse.table(from: state) { return known }
        let built = build(from: state)
        reverse.store(built, from: state)
        return built
    }

    /// Every output a chain of up to five keys types from `start`, with the state each leaves,
    /// found breadth first: single keys, then dead-key pairs, then the longer chains syllabaries
    /// use. Shortest chain first and cheapest keys first within a length, so the first keys listed
    /// for an output are the ones a person would press; later ones leave a different state, for
    /// when the first leaves no way to type what follows.
    private func build(from start: UInt32) -> ReverseTable.Table {
        var entries: [String: [ReverseTable.Entry]] = [:]
        var frontier: [(state: UInt32, path: [KeyStroke])] = [(start, [])]
        var seen: Set<UInt32> = [start]
        for _ in 0..<5 {
            var deeper: [(state: UInt32, path: [KeyStroke])] = []
            for (state, path) in frontier {
                for step in transitions(from: state) {
                    if step.output.isEmpty {
                        // Into any state not yet reached, the plain one included: a held key may
                        // need a silent key to release it before the next syllable can start.
                        guard step.next != state, !seen.contains(step.next) else { continue }
                        seen.insert(step.next)
                        deeper.append((step.next, path + [step.stroke]))
                    } else {
                        let output = String(String.UnicodeScalarView(step.output))
                        let known = entries[output] ?? []
                        if !known.contains(where: { $0.state == step.next }) {
                            entries[output] =
                                known + [ReverseTable.Entry(strokes: path + [step.stroke], state: step.next)]
                        }
                    }
                }
            }
            frontier = deeper
            if frontier.isEmpty { break }
        }
        let longest = entries.keys.map(\.unicodeScalars.count).max() ?? 1
        return ReverseTable.Table(entries: entries, longest: longest)
    }

    /// Every key pressed from `state`, cheapest first: plain before shifted before option. What it
    /// types and the state it leaves are translated once per state and kept; building the tables
    /// asks the same questions of each state many times over.
    private func transitions(from state: UInt32) -> [ReverseTable.Transition] {
        reverse.transitions(from: state) {
            withLayout { layout in
                Self.allStrokes.map { stroke in
                    var next = state
                    let output = Self.translate(layout, stroke.keyCode, stroke.modifiers, &next)
                    return ReverseTable.Transition(stroke: stroke, output: Array(output.unicodeScalars), next: next)
                }
            }
        }
    }

    private static let allStrokes: [KeyStroke] = {
        let codes = Array(UInt16(0)...50).filter { ![36, 48, 49].contains($0) } + [93, 94]
        return [(false, false), (true, false), (false, true), (true, true)].flatMap { shift, option in
            codes.map { KeyStroke($0, shift: shift, option: option) }
        }
    }()

    private func withLayout<T>(_ body: (UnsafePointer<UCKeyboardLayout>) -> T) -> T {
        data.withUnsafeBytes { raw in body(raw.baseAddress!.assumingMemoryBound(to: UCKeyboardLayout.self)) }
    }

    private static func translate(
        _ layout: UnsafePointer<UCKeyboardLayout>, _ keyCode: UInt16, _ modifiers: UInt32,
        _ deadKeys: inout UInt32
    ) -> String {
        var length = 0
        var chars = [UniChar](repeating: 0, count: 8)
        let status = UCKeyTranslate(
            layout, keyCode, UInt16(kUCKeyActionDown), modifiers, UInt32(LMGetKbdType()), 0,
            &deadKeys, chars.count, &length, &chars)
        return status == noErr ? String(utf16CodeUnits: chars, count: length) : ""
    }
}

/// What the layout has answered so far about typing in reverse, kept for the layout's lifetime:
/// the output-to-keys table of each dead-key state a word has been in, each state's key
/// transitions, and whether a word can end in it. Most layouts are never asked, and most that are
/// never leave the plain state.
private final class ReverseTable: @unchecked Sendable {
    struct Entry {
        var strokes: [KeyStroke]
        /// The dead-key state the keys leave, which decides the table for what follows.
        var state: UInt32
    }

    struct Table {
        /// The keys that type each output, shortest and cheapest first, one per state they leave.
        var entries: [String: [Entry]]
        var longest: Int
    }

    struct Transition {
        var stroke: KeyStroke
        var output: [Unicode.Scalar]
        var next: UInt32
    }

    private let lock = NSLock()
    private var tables: [UInt32: Table] = [:]
    private var transitions: [UInt32: [Transition]] = [:]
    private var clean: [UInt32: Bool] = [:]

    func table(from state: UInt32) -> Table? {
        lock.lock()
        defer { lock.unlock() }
        return tables[state]
    }

    /// Tables are built outside the lock, from the cached transitions; two threads building the
    /// same one arrive at the same answer.
    func store(_ table: Table, from state: UInt32) {
        lock.lock()
        defer { lock.unlock() }
        tables[state] = table
    }

    func transitions(from state: UInt32, _ translate: () -> [Transition]) -> [Transition] {
        lock.lock()
        defer { lock.unlock() }
        if let known = transitions[state] { return known }
        let found = translate()
        transitions[state] = found
        return found
    }

    func clean(_ state: UInt32, _ test: () -> Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if let known = clean[state] { return known }
        let result = test()
        clean[state] = result
        return result
    }
}

extension KeyStroke {
    /// Modifier state in the form `UCKeyTranslate` expects: Carbon modifier bits shifted down a byte.
    var modifiers: UInt32 {
        var bits = 0
        if shift { bits |= shiftKey }
        if option { bits |= optionKey }
        if capsLock { bits |= alphaLock }
        return UInt32((bits >> 8) & 0xFF)
    }
}
