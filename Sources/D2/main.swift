import Foundation
import SwiftDiscord
import D2Commands
import D2Utils

/** Registers all available commands. */
func register(commandsFor handler: CommandHandler) {
	handler["ping"] = PingCommand()
	handler["vertical"] = VerticalCommand()
	handler["bf"] = BFCommand()
	handler["bfencode"] = BFEncodeCommand()
	handler["bftoc"] = BFToCCommand()
	handler["echo"] = EchoCommand()
	handler["campus"] = CampusCommand()
	handler["type"] = TriggerTypingCommand()
	handler["mdb"] = MDBCommand()
	handler["timetable"] = TimeTableCommand()
	handler["univis"] = UnivISCommand()
	handler["reddit"] = RedditCommand()
	handler["grant"] = GrantPermissionCommand(permissionManager: handler.permissionManager)
	handler["revoke"] = RevokePermissionCommand(permissionManager: handler.permissionManager)
	handler["permissions"] = ShowPermissionsCommand(permissionManager: handler.permissionManager)
	handler["for"] = ForCommand()
	handler["void"] = VoidCommand()
	handler["grep"] = GrepCommand()
	handler["last"] = LastMessageCommand()
	handler["+"] = BinaryOperationCommand<Double>(name: "addition", operation: +)
	handler["-"] = BinaryOperationCommand<Double>(name: "subtraction", operation: -)
	handler["*"] = BinaryOperationCommand<Double>(name: "multiplication", operation: *)
	handler["/"] = BinaryOperationCommand<Double>(name: "division", operation: /)
	handler["%"] = BinaryOperationCommand<Int>(name: "remainder", operation: %)
	handler["rpn"] = EvaluateExpressionCommand(parser: RPNExpressionParser(), name: "Reverse Polish Notation")
	handler["math"] = EvaluateExpressionCommand(parser: InfixExpressionParser(), name: "Infix Notation")
	handler["maxima"] = MaximaCommand()
	handler["wolframalpha"] = WolframAlphaCommand()
	handler["tictactoe"] = GameCommand<TicTacToeGame>()
	handler["uno"] = GameCommand<UnoGame>()
	handler["sourcefile"] = SourceFileCommand()
	handler["chess"] = GameCommand<ChessGame>()
	handler["cyclethrough"] = CycleThroughCommand()
	handler["demoimage"] = DemoImageCommand()
	handler["latex"] = LatexCommand()
	handler["piglatin"] = PigLatinCommand()
	handler["markov"] = MarkovCommand()
	handler["poll"] = PollCommand()
	handler["concat"] = ConcatCommand()
	handler["preconcat"] = PreConcatCommand()
	handler["presence"] = PresenceCommand()
	handler["dm"] = DirectMessageCommand()
	handler["tofile"] = ToFileCommand()
	handler["chord"] = GuitarChordCommand()
	handler["web"] = WebCommand()
	handler["help"] = HelpCommand(permissionManager: handler.permissionManager)
}

func main() throws {
	let args = CommandLine.arguments
	let handler = try CommandHandler(withPrefix: "%", initialPresence: args[safely: 1])
	let token = try DiskJsonSerializer().readJson(as: Token.self, fromFile: "local/discordToken.json").token
	let client = DiscordClient(token: DiscordToken(stringLiteral: "Bot \(token)"), delegate: handler, configuration: [.log(.info)])
	
	register(commandsFor: handler)
	
	print("Connecting client")
	client.connect()
	RunLoop.current.run()
}

try main()
