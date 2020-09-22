import D2Utils
import D2Graphics

struct CodenamesBoardView {
    let image: Image

    init(model: CodenamesBoardModel) throws {
        let fieldIntSize = Vec2<Int>(x: 100, y: 50)
        let intSize = fieldIntSize * Vec2<Int>(x: model.width, y: model.height)
        let fieldSize = fieldIntSize.asDouble

        let image = try Image(fromSize: intSize)
        var graphics = CairoGraphics(fromImage: image)

        for y in 0..<model.height {
            for x in 0..<model.width {
                let card = model[y, x]
                let color = Self.colorOf(card: card)
                graphics.draw(Rectangle(fromX: Double(x) * fieldSize.x, y: Double(y) * fieldSize.y, width: fieldSize.x, height: fieldSize.y, color: color))
            }
        }

        self.image = image
    }

    private static func colorOf(card: CodenamesBoardModel.Card) -> Color {
        switch card.agent {
            case .role(.red): return Colors.red
            case .role(.blue): return Colors.blue
            case .innocent: return Colors.yellow
            case .assasin: return Colors.black
        }
    }
}
