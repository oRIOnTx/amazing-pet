import CoreGraphics
import Foundation
import Testing
@testable import AmazingPetCore

struct PetLookTests {
    private func pixels(_ image: CGImage) -> Data {
        image.dataProvider!.data! as Data
    }

    @Test(arguments: Species.allCases)
    func everyCoatOfSpeciesLooksDifferent(species: Species) {
        let images = species.coats.map { pixels(PetSprites(look: PetLook(species: species, coat: $0)).walk[0].right) }
        #expect(Set(images).count == species.coats.count)
    }

    @Test(arguments: Species.allCases)
    func speciesHasUniqueCoats(species: Species) {
        #expect(!species.coats.isEmpty)
        #expect(Set(species.coats).count == species.coats.count)
    }

    @Test func eyeColorChangesAwakeFramesOnly() {
        let dark = PetSprites(look: PetLook(eyes: .dark))
        let blue = PetSprites(look: PetLook(eyes: .blue))
        #expect(pixels(dark.walk[0].right) != pixels(blue.walk[0].right))
        #expect(pixels(dark.rest.right) == pixels(blue.rest.right))
    }

    @Test func lookDoesNotRecolorToys() {
        let colors = PetLook(coat: .black, eyes: .green).colors
        #expect(colors["Y"] == Palette.colors["Y"])
        #expect(colors["O"] != Palette.colors["O"])
        #expect(colors["E"] == EyeColor.green.swatch)
    }

    @Test func unsupportedCoatFallsBackToSpeciesDefault() {
        #expect(PetLook(species: .fish, coat: .siamese).coat == Species.fish.coats[0])
        #expect(PetLook(species: .bird).coat == .blue)
        #expect(PetLook(species: .turtle).coat == .green)
    }

    @Test func switchingSpeciesKeepsSharedCoatOrResets() {
        var look = PetLook(species: .cat, coat: .gray)
        look.species = .dog
        #expect(look.coat == .gray)
        look.species = .fish
        #expect(look.coat == Species.fish.coats[0])
    }

    @Test func randomLookIsDeterministicAndValid() {
        #expect(PetLook.random(using: Dice(seed: 4)) == PetLook.random(using: Dice(seed: 4)))
        let looks = (0..<400).map { PetLook.random(using: Dice(seed: UInt64($0))) }
        #expect(Set(looks.map(\.species)).count == Species.allCases.count)
        #expect(Set(looks.map(\.eyes)).count == EyeColor.allCases.count)
        #expect(looks.allSatisfy { $0.species.coats.contains($0.coat) })
    }

    @Test func turtleIsSlowestAndPacesArePositive() {
        let paces = Species.allCases.map(\.pace)
        #expect(paces.allSatisfy { $0 > 0 })
        #expect(Species.turtle.pace == paces.min())
    }

    @Test(arguments: [("  Murka  ", "Murka"), ("", "Pixel"), ("   ", "Pixel"), ("Supercalifragilistic", "Supercalifra")])
    func namesAreCleaned(raw: String, expected: String) {
        #expect(PetProfile.cleanName(raw, fallback: "Pixel") == expected)
    }

    @Test func changingLookRecolorsLivePet() {
        let simulation = PetSimulation(activity: .sleep, dice: Dice(seed: 1))
        let before = simulation.snapshot().pet.sprite
        simulation.look = PetLook(species: .dog, coat: .brown)
        let after = simulation.snapshot().pet.sprite
        #expect(before !== after)
        #expect(after.rows == Species.dog.art.rest)
    }

    @Test func settingSameLookKeepsSprites() {
        let simulation = PetSimulation(activity: .sleep, look: PetLook(coat: .white), dice: Dice(seed: 1))
        let before = simulation.snapshot().pet.sprite
        simulation.look = PetLook(coat: .white)
        #expect(simulation.snapshot().pet.sprite === before)
    }
}
