import AppKit
import CryptoKit
import Foundation
import SwiftUI
import Testing

@testable import CommonUI

@Suite struct TokensTests {
    /// packages/common-ui/tokens.json, four directories up from this file.
    private static let source = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "packages/common-ui/tokens.json")

    @Test func generatedSwiftMatchesTheSource() throws {
        // build.mjs writes the source's hash into Tokens.swift. A different hash means tokens.json
        // changed and nobody ran `node packages/common-ui/build.mjs`.
        let data = try Data(contentsOf: Self.source)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        #expect(Tokens.sourceHash == hash, "tokens.json changed; run `node packages/common-ui/build.mjs`")
    }

    @Test func everyColourResolvesInBothAppearances() throws {
        let colours: [(String, SemanticColor)] = [
            ("text.primary", Tokens.Text.primary), ("text.secondary", Tokens.Text.secondary),
            ("text.inverse", Tokens.Text.inverse), ("surface.base", Tokens.Surface.base),
            ("surface.card", Tokens.Surface.card), ("color.accent", Tokens.Color.accent),
            ("color.border", Tokens.Color.border), ("color.borderCard", Tokens.Color.borderCard),
            ("color.danger", Tokens.Color.danger),
        ]
        for appearance in [NSAppearance.Name.aqua, .darkAqua] {
            let resolved = try #require(NSAppearance(named: appearance))
            for (name, colour) in colours {
                var components: NSColor?
                resolved.performAsCurrentDrawingAppearance {
                    components = colour.nsColor.usingColorSpace(.sRGB)
                }
                #expect(components != nil, "\(name) has no sRGB value in \(appearance.rawValue)")
                #expect(colour.color != Color.clear)
            }
        }
    }

    @Test func ourColoursFollowTheAppearance() {
        // The card tint is dark ink over a light window and light ink over a dark one.
        var light = CGFloat(0)
        var dark = CGFloat(0)
        NSAppearance(named: .aqua)?.performAsCurrentDrawingAppearance {
            light = Tokens.Surface.card.nsColor.usingColorSpace(.sRGB)?.redComponent ?? -1
        }
        NSAppearance(named: .darkAqua)?.performAsCurrentDrawingAppearance {
            dark = Tokens.Surface.card.nsColor.usingColorSpace(.sRGB)?.redComponent ?? -1
        }
        #expect(light == 0)
        #expect(dark == 1)
        #expect(abs(Tokens.Surface.card.nsColor.alphaComponent - 0.047) < 0.001)
    }

    @Test func scalesAreOrdered() {
        let space = [
            Tokens.Space.xxs, Tokens.Space.xs, Tokens.Space.sm, Tokens.Space.md, Tokens.Space.lg, Tokens.Space.xl,
            Tokens.Space.xxl, Tokens.Space.xxxl, Tokens.Space.section,
        ]
        #expect(space == space.sorted())
        #expect(Set(space).count == space.count)
        #expect(Tokens.Radius.sm < Tokens.Radius.md && Tokens.Radius.md < Tokens.Radius.lg)
        #expect(Tokens.Motion.fast < Tokens.Motion.base && Tokens.Motion.base < Tokens.Motion.slow)
    }

    @Test @MainActor func motionIsNilOnlyUnderReducedMotion() {
        let animation = Tokens.Motion.animation()
        #expect((animation == nil) == NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    }
}
