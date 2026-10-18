import Foundation
import Testing

@testable import DesignRender

@Suite struct DesignRenderTests {
    @Test func rendersAreDrawnFromTheCurrentSources() throws {
        // The renderer writes the sources' hash into renders.json. A different hash means a primitive
        // changed and the design page still shows how it looked before.
        let data = try Data(contentsOf: DesignRender.manifest)
        let manifest = try JSONDecoder().decode(DesignRender.Manifest.self, from: data)
        #expect(
            manifest.sourceHash == (try DesignRender.sourceHash()),
            "CommonUI changed since site/static/design was drawn; run `\(DesignRender.command)`")
    }

    @Test func everyRenderIsOnDisk() throws {
        let data = try Data(contentsOf: DesignRender.manifest)
        let manifest = try JSONDecoder().decode(DesignRender.Manifest.self, from: data)
        #expect(!manifest.renders.isEmpty)
        for render in manifest.renders {
            for appearance in ["light", "dark"] {
                let path = DesignRender.output.appending(path: "\(render.name)-\(appearance).png").path
                #expect(FileManager.default.fileExists(atPath: path), "\(path) is missing")
            }
        }
    }

    @Test func theHashCoversEveryCommonUIFileAndTheRenderer() throws {
        let sources = try DesignRender.sources()
        #expect(sources.contains("packages/CommonKit/Sources/CommonUI/Card.swift"))
        #expect(sources.contains("packages/CommonKit/Sources/CommonUI/Settings.swift"))
        #expect(sources.contains("packages/CommonKit/Sources/DesignRender/DesignRender.swift"))
        #expect(sources == sources.sorted())
    }
}
