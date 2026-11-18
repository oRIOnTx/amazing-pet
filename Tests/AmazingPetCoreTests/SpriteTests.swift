import Testing
@testable import AmazingPetCore

struct SpriteTests {
    @Test func rendersImagesMatchingRowSize() {
        let sprite = Sprite(["K.", "KK", ".K"])
        #expect(sprite.width == 2)
        #expect(sprite.height == 3)
        #expect(sprite.right.width == 2)
        #expect(sprite.left.height == 3)
    }

    @Test func picksImageByDirection() {
        let sprite = Sprite(["KO"])
        #expect(sprite.image(facingRight: true) === sprite.right)
        #expect(sprite.image(facingRight: false) === sprite.left)
    }

    @Test func allSpritesUseKnownPaletteColors() {
        let known = Set(Palette.colors.keys).union([Palette.transparent])
        for sprite in Sprites.all {
            #expect(sprite.rows.joined().allSatisfy(known.contains))
            #expect(Set(sprite.rows.map(\.count)).count == 1)
        }
    }

    @Test func allSpritesFitOnStage() {
        for sprite in Sprites.all {
            #expect(Double(sprite.width) <= Stage.menuBar.width)
            #expect(Double(sprite.height) <= Stage.menuBar.height)
        }
    }

    @Test(arguments: Species.allCases)
    func speciesFramesAreFullSizeWithKnownColors(species: Species) {
        let known = Set(Palette.colors.keys).union([Palette.transparent])
        for rows in species.art.all {
            #expect(rows.count == 12)
            #expect(rows.allSatisfy { $0.count == 16 })
            #expect(rows.joined().allSatisfy(known.contains))
        }
    }

    @Test(arguments: Species.allCases)
    func restPoseLeavesRoomForEffectsAboveHead(species: Species) {
        #expect(species.art.rest.prefix(3).allSatisfy { $0.allSatisfy { $0 == Palette.transparent } })
    }

    @Test(arguments: Species.allCases)
    func speciesHasTwoFramesPerGait(species: Species) {
        #expect(species.art.walk.count == 2)
        #expect(species.art.run.count == 2)
    }
}
