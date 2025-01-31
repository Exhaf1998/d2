import D2MessageIO
import D2NetAPIs

public class JokeCommand: VoidCommand {
    public let info = CommandInfo(
        category: .fun,
        shortDescription: "Tells a joke!",
        presented: true,
        requiredPermissionLevel: .basic
    )

    public init() {}

    public func invoke(output: CommandOutput, context: CommandContext) {
        RandomJokeQuery().perform().listen {
            do {
                let joke = try $0.get()
                output.append(Embed(
                    title: joke.setup,
                    description: joke.punchline
                ))
            } catch {
                output.append(error, errorText: "Could not fetch joke")
            }
        }
    }
}
