import Testing

@testable import CommonKit

@Suite struct VersionTests {
    @Test func readsPlainVersionsAndReleaseTags() {
        #expect(Version("0.4.0") == Version(0, 4, 0))
        #expect(Version("v1.2.3") == Version(1, 2, 3))
        #expect(Version("bar-v0.4.10") == Version(0, 4, 10))
        #expect(Version("stats-v12.0.1") == Version(12, 0, 1))
        #expect(Version("1.2") == Version(1, 2, 0))
    }

    @Test func refusesWhatIsNotAVersion() {
        for text in ["", "v", "bar-v", "0.4.0-beta", "1..2", "a.b.c", "1.2.3.4", "0.4.", "bar-v0.4.0 (1)"] {
            #expect(Version(text) == nil, "\(text) read as a version")
        }
    }

    @Test func comparesNumerically() {
        #expect(Version(0, 9, 0) < Version(0, 10, 0))
        #expect(Version(0, 4, 10) > Version(0, 4, 9))
        #expect(Version(1, 0, 0) > Version(0, 99, 99))
        #expect(Version(0, 4, 0) == Version("0.4.0"))
        #expect(
            [Version(0, 10, 0), Version(0, 9, 1), Version(0, 9, 0)].sorted() == [
                Version(0, 9, 0), Version(0, 9, 1), Version(0, 10, 0),
            ])
    }

    @Test func printsItselfBack() {
        #expect(Version("bar-v0.4.0")?.description == "0.4.0")
        #expect(Version("1.2")?.description == "1.2.0")
    }
}
