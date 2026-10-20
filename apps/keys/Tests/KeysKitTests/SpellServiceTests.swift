import Foundation
import Testing

@testable import KeysKit

/// A spell checker in a chosen state: which words it knows, whether it completes, and whether it
/// passes any string at all, as some real dictionaries do.
@MainActor
final class FakeSpellService: SpellService {
    var words: Set<String>
    var completes: Bool
    var lenient: Bool
    /// Words it accepts but never lists among completions, as macOS 26's English does with names.
    var unlisted: Set<String> = []
    /// How long each completion takes, for a spell service under load.
    var delay: Duration = .zero
    var languages: [String] { ["ru"] }

    init(words: Set<String>, completes: Bool, lenient: Bool = false) {
        (self.words, self.completes, self.lenient) = (words, completes, lenient)
    }

    func accepts(_ word: String, dictionary: String) -> Bool { lenient || words.contains(word) }

    private(set) var completionCalls = 0

    func completions(_ prefix: String, dictionary: String) -> [String] {
        completionCalls += 1
        if delay > .zero { Thread.sleep(forTimeInterval: Double(delay.components.attoseconds) / 1e18) }
        guard completes else { return [] }
        // A full list for any start, as a working dictionary gives.
        return words.filter { $0.hasPrefix(prefix) && !unlisted.contains($0) } + (0..<20).map { "\(prefix)\($0)" }
    }
}

@MainActor
struct SpellServiceTests {
    let russian: Set<String> = ["привет", "пока", "как"]

    @Test func withCompletionsAWordMustBeListed() {
        let lexicon = SystemLexicon(spelling: FakeSpellService(words: russian, completes: true))
        #expect(lexicon.isWord("привет", language: "ru") == true)
        #expect(lexicon.startsWord("при", language: "ru") == true)
    }

    /// macOS 26's English accepts "David" but lists nothing for it. A name a strict dictionary
    /// accepts only capitalised is a word, not evidence for converting it.
    @Test func aNameTheDictionaryListsNothingForIsStillAWord() {
        let spelling = FakeSpellService(words: russian.union(["Давид"]), completes: true)
        spelling.unlisted = ["Давид"]
        let lexicon = SystemLexicon(spelling: spelling)
        #expect(lexicon.isWord("Давид", language: "ru") == true)
        #expect(lexicon.isWord("давид", language: "ru") == false)
    }

    /// Only a capitalised word refused in lower case counts as a name; anything else unlisted doesn't.
    @Test func anUnlistedWordThatIsNoNameIsNotAWord() {
        let spelling = FakeSpellService(words: russian.union(["Пока", "ПРИВЕТ"]), completes: true)
        spelling.unlisted = ["Пока", "ПРИВЕТ"]
        let lexicon = SystemLexicon(spelling: spelling)
        #expect(lexicon.isWord("Пока", language: "ru") == false)
        #expect(lexicon.isWord("ПРИВЕТ", language: "ru") == false)
    }

    /// A dictionary that passes anything gets no such allowance: there, only listing counts.
    @Test func aLenientDictionaryNeedsTheWordListed() {
        let spelling = FakeSpellService(words: russian.union(["Давид"]), completes: true, lenient: true)
        spelling.unlisted = ["Давид"]
        let lexicon = SystemLexicon(spelling: spelling)
        #expect(lexicon.isWord("Давид", language: "ru") == false)
    }

    @Test func withoutCompletionsTheSpellCheckDecides() {
        let lexicon = SystemLexicon(spelling: FakeSpellService(words: russian, completes: false))
        #expect(lexicon.isWord("привет", language: "ru") == true)
        #expect(lexicon.isWord("руддщ", language: "ru") == false)
        #expect(lexicon.startsWord("при", language: "ru") == nil)
    }

    /// A dictionary that passes anything says nothing on its own; without completions it is no
    /// evidence either way, rather than a yes for every string.
    @Test func aLenientDictionaryWithoutCompletionsHasNoOpinion() {
        let lexicon = SystemLexicon(spelling: FakeSpellService(words: russian, completes: false, lenient: true))
        #expect(lexicon.isWord("руддщ", language: "ru") == nil)
    }

    /// A spell service taking a fifth of a second a call would hold a 64-call probe for thirteen
    /// seconds; the probe gives up within its budget and falls back to the spell check.
    /// The probe happens when the app asks at launch; a word typed later costs one lookup, not a probe.
    @Test func checkingAtLaunchLeavesNothingForTheFirstWord() throws {
        let spelling = FakeSpellService(words: russian, completes: true)
        let lexicon = SystemLexicon(spelling: spelling)
        lexicon.checkSpelling(for: try #require(InputSources.keyboard("com.apple.keylayout.Russian")))
        let afterProbe = spelling.completionCalls
        #expect(afterProbe > 1)
        _ = lexicon.isWord("привет", language: "ru")
        #expect(spelling.completionCalls == afterProbe + 1)
    }

    @Test func aSlowSpellServiceCannotStallTheProbe() {
        let spelling = FakeSpellService(words: russian, completes: false)
        spelling.delay = .milliseconds(200)
        let lexicon = SystemLexicon(spelling: spelling)
        let clock = ContinuousClock()
        let start = clock.now
        #expect(lexicon.isWord("привет", language: "ru") == true)
        // Five calls at 200 ms are a second on their own; the gate is against the thirteen.
        #expect(clock.now - start < .seconds(3))
        #expect(spelling.completionCalls <= 5)
    }

    @Test func aWorkingDictionaryIsKnownAfterThreeAnswers() {
        let spelling = FakeSpellService(words: russian, completes: true)
        let lexicon = SystemLexicon(spelling: spelling)
        _ = lexicon.startsWord("при", language: "ru")
        // Three probe starts, then the start itself.
        #expect(spelling.completionCalls == 4)
    }

    /// A spell service that answers the probe quickly but turns slow mid-harvest gives up within one
    /// slow call, with nothing listed and completions counted as down.
    @Test func aSlowHarvestGivesUp() throws {
        let spelling = FakeSpellService(words: russian, completes: true)
        let lexicon = SystemLexicon(spelling: spelling)
        let russianKeyboard = try #require(InputSources.keyboard("com.apple.keylayout.Russian"))
        lexicon.checkSpelling(for: russianKeyboard)
        spelling.delay = .milliseconds(300)
        let before = spelling.completionCalls
        let clock = ContinuousClock()
        let start = clock.now
        #expect(lexicon.wordList(for: russianKeyboard) == nil)
        #expect(clock.now - start < .seconds(1))
        #expect(spelling.completionCalls == before + 1)
        #expect(lexicon.startsWord("при", language: "ru") == nil)
    }

    @Test func noWordListIsHarvestedWhileCompletionsAreDown() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "KeysKitTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let lexicon = SystemLexicon(spelling: FakeSpellService(words: russian, completes: false))
        let keyboard = try #require(InputSources.keyboard("com.apple.keylayout.Russian"))
        #expect(lexicon.wordList(for: keyboard) == nil)
        #expect(!FileManager.default.fileExists(atPath: folder.path))
    }
}
