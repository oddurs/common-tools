import Testing

@testable import CommonKit

@Suite struct CommonToolsSectionTests {
    @Test @MainActor func thePromiseIsWordForWord() {
        // The site and the READMEs make the same promise; the apps make it in these words.
        #expect(
            CommonToolsSection.promise
                == "Free and open source, forever. Nothing you do is ever reported; nothing leaves your Mac.")
    }
}
