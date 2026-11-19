public struct Home {
    public let sprite: Sprite
    public let unease: Sprite

    static func dry(_ sprite: Sprite) -> Home { Home(sprite: sprite, unease: Sprites.sweat) }
    static let aquarium = Home(sprite: Sprites.aquarium, unease: Sprites.bubble)
}
