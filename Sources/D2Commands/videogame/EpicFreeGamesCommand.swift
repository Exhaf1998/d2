import D2MessageIO
import D2NetAPIs

public class EpicFreeGamesCommand: StringCommand {
    public let info = CommandInfo(
        category: .videogame,
        shortDescription: "Fetches current free games from the Epic Games Store",
        requiredPermissionLevel: .basic
    )

    public init() {}

    public func invoke(with input: String, output: CommandOutput, context: CommandContext) {
        EpicFreeGamesQuery().perform().listen {
            do {
                let games = try $0.get().data.catalog.searchStore.elements
                output.append(Embed(
                    title: "Free Games in the Epic Store",
                    fields: games
                        .prefix(5)
                        .map { Embed.Field(name: $0.title, value: self.format(game: $0) ?? "_no info_") }
                ))
            } catch {
                output.append(error, errorText: "Could not query games")
            }
        }
    }

    private func format(game: EpicFreeGames.ResponseData.Catalog.SearchStore.Element) -> String? {
        let fmtPrice = game.price?.totalPrice?.fmtPrice
        return [
            (fmtPrice?.originalPrice).map { "~~\($0)~~" },
            fmtPrice?.discountPrice,
            (game.seller?.name).map { "- by \($0)" }
        ].compactMap { $0 }.joined(separator: " ").nilIfEmpty
    }
}
