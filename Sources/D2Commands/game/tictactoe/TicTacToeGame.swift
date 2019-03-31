public struct TicTacToeGame: Game {
	public typealias State = TicTacToeState
	
	public let name: String = "tic tac toe"
	public let actions: [String: (State, String) throws -> ActionResult<State>] = [
		"move": { state, args in ActionResult(nextState: try state.childState(after: try State.Move.init(fromString: args))) },
		"cancel": { state, _ in ActionResult(nextState: state, cancelsMatch: true) }
	]
	
	public init() {}
}