import Testing

@testable import ShotKit

@Suite struct ImageSizeTests {
    @Test func promptSizeCapsAFullRetinaScreen() {
        let size = ImageSize.prompt.fit(width: 3456, height: 2234)
        #expect(size.width == 1568)
        #expect(size.height == 1014)
    }

    @Test func promptSizeCapsTheLongEdgeWhicheverItIs() {
        let size = ImageSize.prompt.fit(width: 800, height: 4000)
        #expect(size.height == 1568)
        #expect(size.width == 314)
    }

    @Test func promptSizeLeavesAnOrdinaryCropAlone() {
        let size = ImageSize.prompt.fit(width: 1280, height: 760)
        #expect(size == (1280, 760))
    }

    @Test func fullSizeNeverChanges() {
        #expect(ImageSize.full.fit(width: 6016, height: 3384) == (6016, 3384))
    }

    @Test func degenerateSizesPassThrough() {
        #expect(ImageSize.prompt.fit(width: 0, height: 10) == (0, 10))
    }

    @Test func tokensFollowPixelsUpToTheModelsOwnLimit() {
        #expect(ImageSize.estimatedTokens(width: 750, height: 100) == 100)
        // A full 2× screen costs the ceiling, not 10,000.
        #expect(ImageSize.estimatedTokens(width: 3456, height: 2234) == 4784)
        let prompt = ImageSize.prompt.fit(width: 3456, height: 2234)
        #expect(ImageSize.estimatedTokens(width: prompt.width, height: prompt.height) == 2120)
    }

    @Test(arguments: [
        (840, "≈ 840 tokens"), (999, "≈ 999 tokens"), (1000, "≈ 1.0k tokens"), (2120, "≈ 2.1k tokens"),
        (4784, "≈ 4.8k tokens"),
    ])
    func tokensReadShort(count: Int, text: String) {
        #expect(ImageSize.describe(tokens: count) == text)
    }
}
