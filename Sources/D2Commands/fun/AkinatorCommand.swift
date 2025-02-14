import D2MessageIO
import D2NetAPIs

fileprivate let progressionThreshold: Double = 85 // percent

public class AkinatorCommand: StringCommand {
    public let info = CommandInfo(
        category: .fun,
        shortDescription: "Plays the akinator game, also known as '20 Questions'",
        helpText: """
            Syntax: [cancel]?

            Valid answers are \(AkinatorAnswer.allCases.map(\.rawValue).joined(separator: ", "))
            """,
        requiredPermissionLevel: .basic
    )
    private var sessions: [ChannelID: AkinatorSession] = [:]

    public init() {}

    public func invoke(with input: String, output: CommandOutput, context: CommandContext) {
        guard let channelId = context.channel?.id else {
            output.append(errorText: "Not in a channel!")
            return
        }

        if input == "cancel" {
            guard sessions.keys.contains(channelId) else {
                output.append(errorText: "There is no session running on this channel!")
                return
            }

            context.unsubscribeFromChannel()
            sessions[channelId] = nil
            output.append("Successfully cancelled game!")
        } else {
            guard !sessions.keys.contains(channelId) else {
                output.append(errorText: "There is already a session running in this channel!")
                return
            }

            AkinatorSession.create().listen {
                do {
                    let (session, question) = try $0.get()
                    output.append(self.embed(of: question))

                    self.sessions[channelId] = session
                    context.subscribeToChannel()
                } catch {
                    output.append(error, errorText: "Could not create Akinator session")
                }
            }
        }

    }

    public func onSubscriptionMessage(with content: String, output: CommandOutput, context: CommandContext) {
        guard let channelId = context.channel?.id, let session = sessions[channelId] else {
            context.unsubscribeFromChannel()
            return
        }
        guard let answer = AkinatorAnswer(rawValue: content.lowercased()) else {
            return
        }

        session.answer(with: answer).listen {
            do {
                let question = try $0.get()
                if question.progression > progressionThreshold {
                    session.guess().listen {
                        do {
                            guard let guess = try $0.get().first else { throw AkinatorError.noGuesses }
                            output.append(self.embed(of: guess))
                        } catch {
                            output.append(error, errorText: "Error while guessing")
                        }

                        self.sessions[channelId] = nil
                        context.unsubscribeFromChannel()
                    }
                } else {
                    output.append(self.embed(of: question))
                }
            } catch {
                output.append(error, errorText: "Error while answering")
            }
        }
    }

    private func embed(of guess: AkinatorGuess) -> Embed {
        Embed(
            title: ":genie: I am \(Int(guess.probability * 100))% sure that you are thinking of \(guess.name)",
            image: guess.photoPath.map(Embed.Image.init(url:))
        )
    }

    private func embed(of question: AkinatorQuestion) -> Embed {
        Embed(
            title: ":genie: Akinator Question",
            description: question.text,
            footer: Embed.Footer(text: "Step: \(question.step), progress: \(Int(question.progression))%")
        )
    }
}
