import Foundation
import Dispatch
import SwiftDiscord
import D2Utils
import D2Permissions
import D2Script

public class D2ScriptCommand: StringCommand {
	public let description: String
	public let sourceFile: String = #file
	public let requiredPermissionLevel: PermissionLevel
	public let name: String
	private let script: D2Script
	private var running = false
	private var semaphore = DispatchSemaphore(value: 0)
	
	public init(script: D2Script) throws {
		self.script = script
		
		let executor = D2ScriptExecutor()
		executor.run(script)
		
		let commandNames = executor.topLevelStorage.commandNames
		guard let name = commandNames.first else { throw D2ScriptCommandError.noCommandDefined("Script defines no 'command { ... }' blocks") }
		guard commandNames.count == 1 else { throw D2ScriptCommandError.multipleCommandsDefined("Currently only one command declaration per script is supported") }
		
		self.name = name
		description = executor.topLevelStorage[string: "description"] ?? "Anonymous D2Script"
		requiredPermissionLevel = executor.topLevelStorage[string: "requiredPermissionLevel"].flatMap { PermissionLevel.of($0) } ?? .vip
	}
	
	private func addBuiltInFunctions(storage: D2ScriptStorage, input: String, output: CommandOutput) {
		// Output to Discord
		storage[function: "output"] = {
			guard let value = $0.first else {
				output.append("output(...) received no arguments")
				return nil
			}
			switch value {
				case let .string(str)?:
					output.append(str)
				case let .number(num)?:
					output.append(String(num))
				default:
					output.append(String(describing: value))
			}
			return nil
		}
		
		// Print something to the console
		storage[function: "print"] = {
			print($0.first.flatMap { $0 } ?? .string(""))
			return nil
		}
		
		// Perform a synchronous GET request
		storage[function: "httpGet"] = {
			guard case let .string(rawUrl)?? = $0.first else {
				output.append("httpGet(...) received no arguments")
				return nil
			}
			guard let url = URL(string: rawUrl) else {
				output.append("Invalid URL: \(rawUrl)")
				return nil
			}
			
			var result: String? = nil
			
			URLSession.shared.dataTask(with: url) { (data, response, error) in
				guard error == nil else {
					output.append("An error occurred while performing the HTTP request")
					self.semaphore.signal()
					return
				}
				guard let str = data.flatMap({ String(data: $0, encoding: .utf8) })?.truncate(1000) else {
					output.append("Could not fetch data as UTF-8 string")
					self.semaphore.signal()
					return
				}
				result = str
				self.semaphore.signal()
			}.resume()
			
			self.semaphore.wait()
			return result.map { .string($0) }
		}
	}
	
	public func invoke(withStringInput input: String, output: CommandOutput, context: CommandContext) {
		guard !running else {
			output.append("This command is already running, wait for it to finish")
			return
		}
		
		running = true
		
		let executor = D2ScriptExecutor()
		executor.run(script)
		addBuiltInFunctions(storage: executor.topLevelStorage, input: input, output: output)
		
		let queue = DispatchQueue(label: "D2Script command \(name)")
		let task = DispatchWorkItem {
			executor.call(command: self.name)
		}
		
		let timeout = DispatchTime.now() + .seconds(15)
		queue.async(execute: task)
		
		DispatchQueue.global(qos: .utility).async {
			_ = task.wait(timeout: timeout)
			self.semaphore.signal()
			self.semaphore = DispatchSemaphore(value: 0)
			self.running = false
		}
	}
}