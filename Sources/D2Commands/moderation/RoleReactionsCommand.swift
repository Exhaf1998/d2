import D2MessageIO
import Utils

fileprivate let argsPattern = try! Regex(from: "(\\w+)\\s+<#(\\d+)>\\s+(\\d+)\\s*(.*)")

public class RoleReactionsCommand: StringCommand {
    public private(set) var info = CommandInfo(
        category: .moderation,
        shortDescription: "Adds reactions to a message that automatically assign roles",
        requiredPermissionLevel: .vip
    )
    @AutoSerializing private var configuration: RoleReactionsConfiguration
    private var subcommands: [String: (CommandOutput, MessageClient, ChannelID, MessageID, String) -> Void] = [:]

    public init(configuration: AutoSerializing<RoleReactionsConfiguration>) {
        self._configuration = configuration
        subcommands = [
            "attach": { [unowned self] output, client, channelId, messageId, args in
                guard let guild = client.guildForChannel(channelId) else {
                    output.append(errorText: "Not on a guild!")
                    return
                }
                guard !self.configuration.roleMessages.keys.contains(messageId) else {
                    output.append(errorText: "Please detach this message first!")
                    return
                }

                do {
                    let mappings = try self.parseReactionMappings(from: args, on: guild)
                    self.configuration.roleMessages[messageId] = mappings

                    for (emoji, _) in mappings {
                        // TODO: Handle asynchronous errors
                        client.createReaction(for: messageId, on: channelId, emoji: emoji)
                    }

                    output.append("Successfully added role reactions to the message.")
                } catch {
                    output.append(error, errorText: "Could not attach role reactions.")
                }
            },
            "detach": { [unowned self] output, client, channelId, messageId, _ in
                guard let mappings = self.configuration.roleMessages[messageId] else {
                    output.append(errorText: "This message is not a (known) reaction message!")
                    return
                }

                self.configuration.roleMessages[messageId] = nil

                for (emoji, _) in mappings {
                    // TODO: Handle asynchronous errors
                    client.deleteOwnReaction(for: messageId, on: channelId, emoji: emoji)
                }

                output.append("Successfully removed role reactions from the message.")
            }
        ]
        info.helpText = """
            Syntax: `[subcommand] [#channel] [message id] [args...]`

            For example:
            `attach #my-awesome-channel 123456789012345678 😁=Role a, 👍=Role b`
            `detach #my-awesome-channel 123456789012345678`
            """
    }

    public func invoke(with input: String, output: CommandOutput, context: CommandContext) {
        guard let parsedArgs = argsPattern.firstGroups(in: input) else {
            output.append(errorText: info.helpText!)
            return
        }
        guard let client = context.client else {
            output.append(errorText: "No client available")
            return
        }

        let subcommandName = parsedArgs[1]
        let channelId = ID(parsedArgs[2], clientName: client.name)
        let messageId = ID(parsedArgs[3], clientName: client.name)
        let subcommandArgs = parsedArgs[4]

        guard let subcommand = subcommands[subcommandName] else {
            output.append(errorText: "Unknown subcommand `\(subcommandName)`, try one of these: \(subcommands.keys.map { "`\($0)`" }.joined(separator: ", "))")
            return
        }

        subcommand(output, client, channelId, messageId, subcommandArgs)
    }

    private func parseReactionMappings(from s: String, on guild: Guild) throws -> RoleReactionsConfiguration.Mappings {
        let mappings = try s
            .split(separator: ",")
            .map { $0
                .split(separator: "=")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
            .map { try ($0[0], parseRoleId(from: $0[1], on: guild)) }

        return .init(roleMappings: Dictionary(uniqueKeysWithValues: mappings))
    }

    private func parseRoleId(from s: String, on guild: Guild) throws -> RoleID {
        for (roleId, role) in guild.roles {
            if s == "\(roleId)" || role.name == s {
                return role.id
            }
        }

        throw RoleReactionsError.couldNotParseRole(s)
    }
}