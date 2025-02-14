import D2Permissions
import Foundation
import Dispatch
import Utils

public class EchoCommand: StringCommand {
    public let info = CommandInfo(
        category: .misc,
        shortDescription: "Outputs the string input",
        requiredPermissionLevel: .basic
    )
    public let outputValueType: RichValueType = .text

    public init() {}

    public func invoke(with input: String, output: CommandOutput, context: CommandContext) {
        output.append(input)
    }
}
