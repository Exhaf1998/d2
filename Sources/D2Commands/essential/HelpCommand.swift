import D2MessageIO
import D2Permissions

public class HelpCommand: StringCommand {
	public let info = CommandInfo(
		category: .essential,
		shortDescription: "Helps the user",
		longDescription: "Displays a help embed showing all registered commands",
		requiredPermissionLevel: .basic
	)
	public let outputValueType: RichValueType = .embed
	private let commandPrefix: String
	private let permissionManager: PermissionManager
	
	public init(commandPrefix: String, permissionManager: PermissionManager) {
		self.commandPrefix = commandPrefix
		self.permissionManager = permissionManager
	}
	
	public func invoke(withStringInput input: String, output: CommandOutput, context: CommandContext) {
		if input.isEmpty {
			output.append(generalHelpEmbed(context: context))
		} else {
			if let command = context.registry[input] {
				output.append(commandHelpEmbed(for: input, command: command))
			} else if let category = CommandCategory(rawValue: input) {
				output.append(categoryHelpEmbed(for: category, context: context))
			} else {
				output.append(Embed(
					title: ":warning: Did not recognize command `\(input)`",
					description: "Could not fetch any help"
				))
			}
		}
	}
	
	private func generalHelpEmbed(context: CommandContext) -> Embed {
		return Embed(
			title: ":question: Available Commands",
			fields: CommandCategory.allCases
				.map { category in Embed.Field(
					name: "\(category)",
					value: context.registry
						.filter { $0.value.info.category == category }
						.map { "`\(commandPrefix)\($0.key)`" }
						.joined(separator: ", ")
						+ " (Type `\(commandPrefix)help \(category.rawValue)` for details)"
				) }
		)
	}
	
	private func categoryHelpEmbed(for category: CommandCategory, context: CommandContext) -> Embed {
		let helpGroups = Dictionary(grouping: context.registry.filter { !$0.value.info.hidden && $0.value.info.category == category }, by: { $0.value.info.requiredPermissionLevel })
			.filter { permissionManager[context.author].rawValue >= $0.key.rawValue }
			.sorted { $0.key.rawValue < $1.key.rawValue }
		let helpFields = helpGroups
			.flatMap { (group: (key: PermissionLevel, value: [(key: String, value: Command)])) -> [Embed.Field] in
				let splitGroups = group.value
					.sorted { $0.key < $1.key }
					.map { """
						**\(commandPrefix)\($0.key)**: `\($0.value.inputValueType) -> \($0.value.outputValueType)`
						    \($0.value.info.shortDescription)
						
						""" }
					.chunks(ofLength: 14)
				return splitGroups
					.enumerated()
					.map { Embed.Field(name: ":star: \(group.key) commands (\($0.0 + 1)/\(splitGroups.count))", value: $0.1.joined(separator: "\n")) }
			}
		return Embed(
			title: "\(category) | Available Commands",
			fields: helpFields
		)
	}

	private func commandHelpEmbed(for name: String, command: Command) -> Embed {
		return Embed(
			title: ":question: \(commandPrefix)\(name): `\(command.inputValueType) -> \(command.outputValueType)`",
			description: """
				\(command.info.longDescription)
				
				\(command.info.helpText ?? "")
				""".trimmingCharacters(in: .whitespaces),
			footer: Embed.Footer(text: "\(command.info.category)")
		)
	}
}
