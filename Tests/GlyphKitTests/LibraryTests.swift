import Foundation
import Testing

@testable import GlyphKit

@Suite struct GlyphSpecTests {
    @Test func startsAsTheStarInTheMenuBarsColour() {
        let spec = Library.starter()
        #expect(spec.kind == .text && spec.text == SourceKind.initialText)
        #expect(spec.edit.style == .silhouette)
        #expect(spec.isVisible)
    }

    @Test func eachSourceKeepsItsOwnEdit() {
        var spec = Library.starter()
        spec.edit.scale = 0.6
        spec.setImage(file: "a.png")
        spec.edit.style = .ink
        spec.kind = .text
        #expect(spec.edit.scale == 0.6 && spec.edit.style == .silhouette)
        spec.kind = .image
        #expect(spec.edit.style == .ink)
    }

    @Test func typingAnEmojiSwitchesToColourAndBack() {
        var spec = Library.starter()
        spec.setText("🐈‍⬛")
        #expect(spec.edit.style == .color)
        spec.setText("ok")
        #expect(spec.edit.style == .silhouette)
    }

    @Test func swappingOneEmojiForAnotherKeepsAChosenStyle() {
        var spec = Library.starter()
        spec.setText("🔥")
        spec.edit.style = .silhouette
        spec.setText("🌸")
        #expect(spec.edit.style == .silhouette)
    }

    @Test func typingSwitchesToText() {
        var spec = Library.starter()
        spec.setImage(file: "a.png")
        spec.setText("☾")
        #expect(spec.kind == .text)
    }

    @Test func aNewImageStartsAfreshButKeepsTheSize() {
        var spec = Library.starter()
        spec.setImage(file: "a.png")
        spec.edit.scale = 0.7
        spec.edit.crop = CropRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        spec.setImage(file: "b.png")
        #expect(spec.imageFile == "b.png" && spec.kind == .image)
        #expect(spec.edit.crop.isFull && spec.edit.scale == 0.7)
    }

    @Test func savesItsPositionUnderItsOwnName() {
        let a = Library.starter(), b = Library.starter()
        #expect(a.autosaveName != b.autosaveName)
        #expect(a.autosaveName.hasPrefix("glyph-"))
    }

    @Test func survivesARoundTrip() throws {
        var spec = Library.starter()
        spec.setImage(file: "a.gif")
        spec.name = "Cat"
        let data = try JSONEncoder().encode([spec])
        #expect(try JSONDecoder().decode([GlyphSpec].self, from: data) == [spec])
    }
}

@Suite struct LibraryTests {
    @Test func namesNewGlyphsWithoutRepeating() {
        #expect(Library.freshName(taken: []) == "Glyph")
        #expect(Library.freshName(taken: ["Glyph"]) == "Glyph 2")
        #expect(Library.freshName(taken: ["Glyph", "Glyph 2", "Glyph 4"]) == "Glyph 3")
    }

    @Test func aDuplicateIsItsOwnGlyph() {
        var cat = Library.starter()
        cat.name = "Cat"
        cat.isVisible = false
        let copy = Library.duplicate(cat, among: [cat], imageFile: "copy.png")
        #expect(copy.id != cat.id)
        #expect(copy.name == "Cat copy")
        #expect(copy.imageFile == "copy.png")
        #expect(copy.isVisible)
        #expect(copy.text == cat.text && copy.textEdit == cat.textEdit)
        #expect(Library.duplicate(cat, among: [cat, copy], imageFile: nil).name == "Cat copy 2")
    }

    @Test func theLastVisibleGlyphCannotBeHidden() {
        var a = Library.starter(), b = Library.starter()
        #expect(Library.canHide(a.id, in: [a, b]))
        b.isVisible = false
        #expect(!Library.canHide(a.id, in: [a, b]))
        a.isVisible = false
        #expect(!Library.canHide(a.id, in: [a]))
    }

    @Test func theLastVisibleGlyphCannotBeRemoved() {
        let a = Library.starter()
        var b = Library.starter()
        #expect(!Library.canRemove(a.id, from: [a]))
        #expect(Library.canRemove(a.id, from: [a, b]))
        b.isVisible = false
        #expect(!Library.canRemove(a.id, from: [a, b]))
        // A hidden one can go, as long as another is left.
        #expect(Library.canRemove(b.id, from: [a, b]))
        #expect(!Library.canRemove(UUID(), from: [a, b]))
    }
}
