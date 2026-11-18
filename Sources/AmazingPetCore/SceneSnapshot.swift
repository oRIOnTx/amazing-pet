import Foundation

public struct SceneSnapshot {
    public struct Item {
        public var sprite: Sprite
        public var facingRight = true
        public var x: Double
        public var y: Double
        public var opacity: Float = 1
    }

    public var pet: Item
    public var prop: Item?
    public var effects: [Item] = []
}

enum Effects {
    static func floating(_ sprite: Sprite, from pet: Pet, clock: Double, rate: Double) -> [SceneSnapshot.Item] {
        let direction = pet.facingRight ? 1.0 : -1.0
        let startX = pet.facingRight ? pet.restHeadX : pet.restHeadX - Double(sprite.width)
        return (0..<2).map { i in
            let p = (clock * rate + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
            let x = (startX + direction * p * 8).clamped(to: 0...(pet.stage.width - Double(sprite.width)))
            return .init(
                sprite: sprite, x: x.rounded(), y: max(0, pet.top + Double(5 - sprite.height) - p * 3).rounded(),
                opacity: Float(sin(p * .pi))
            )
        }
    }

    static func blinking(_ sprite: Sprite, over pet: Pet, clock: Double) -> [SceneSnapshot.Item] {
        guard Int(clock * 2) % 2 == 0 else { return [] }
        let x = (pet.restHeadX - Double(sprite.width) / 2).rounded()
        return [.init(sprite: sprite, x: x.clamped(to: 0...(pet.stage.width - Double(sprite.width))), y: max(0, pet.top))]
    }
}
