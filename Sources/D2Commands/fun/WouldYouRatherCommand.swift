import Foundation
import D2Utils
import D2MessageIO
import D2NetAPIs

public class WouldYouRatherCommand: StringCommand {
    public let info = CommandInfo(
        category: .fun,
        shortDescription: "Asks an either/or question",
        requiredPermissionLevel: .basic
    )
    private let emojiA = ":a:"
    private let emojiB = ":regional_indicator_b:"
    
    public init() {}
    
    public func invoke(withStringInput input: String, output: CommandOutput, context: CommandContext) {
        WouldYouRatherQuery().perform {
            do {
                let wyr = try $0.get()
                output.append(Embed(
                    title: wyr.title,
                    description: """
                        \(self.emojiA) \(wyr.choicea)
                        \(self.emojiB) \(wyr.choiceb)
                        """,
                    url: wyr.link.flatMap(URL.init(string:)),
                    footer: Embed.Footer(text: "\(wyr.votes ?? 0) \("vote".pluralize(with: wyr.votes ?? 0)) - Tags: \(wyr.tags ?? "none")")
                ))
            } catch {
                output.append(error, errorText: "Could not fetch question.")
            }
        }
    }
    
    public func onSuccessfullySent(context: CommandContext) {
        guard let messageId = context.message.id, let channelId = context.message.channelId else { return }
        context.client?.createReaction(for: messageId, on: channelId, emoji: emojiA)
        context.client?.createReaction(for: messageId, on: channelId, emoji: emojiB)
    }
}
