import SwiftDiscord
import D2Utils
import D2Graphics
import Dispatch

// The first group matches the language, the second group matches the code
fileprivate let codePattern = try! Regex(from: "`(?:``(?:(\\w*)\n)?)?([^`]+)`*")

/**
 * Parses Discord messages into rich values.
 */
public struct DiscordMessageParser {
	public init() {}
	
	/**
	 * Asynchronously parses a string with its
	 * parent message and downloads
	 * the attachments of a message.
	 */
	public func parse(_ str: String? = nil, message: DiscordMessage, then: @escaping (RichValue) -> Void) {
		var values: [RichValue] = []
		
		// Parse message content
		let content = str ?? message.content
		if let codeGroups = codePattern.firstGroups(in: content) {
			let language = codeGroups[1].nilIfEmpty
			let code = codeGroups[2]
			values.append(.code(code, language: language))
		} else if !content.isEmpty {
			values.append(.text(content))
		}
		
		// Append embeds
		values += message.embeds.map { .embed($0) }
		
		var asyncTaskCount = 0
		let semaphore = DispatchSemaphore(value: 0)
		
		// Fetch attachments
		for attachment in message.attachments {
			let fileName = attachment.filename.lowercased()
			
			if fileName.hasSuffix(".png") {
				// Download PNG attachment
				asyncTaskCount += 1
				attachment.download {
					do {
						let data = try $0.get()
						values.append(.image(try Image(fromPng: data)))
					} catch {
						print(error)
					}
					semaphore.signal()
				}
			} else if fileName.hasSuffix(".gif") {
				// Download GIF attachment
				
				// TODO: Implement animated GIF parser
				
				// asyncTaskCount += 1
				// attachment.download {
				// 	do {
				// 		let data = try $0.get()
				// 		values.append(.gif(try AnimatedGif(from: data)))
				// 	} catch {
				// 		print(error)
				// 	}
				// 	semaphore.signal()
				// }
			}
		}
		
		DispatchQueue.global(qos: .userInitiated).async {
			// Return first once all asynchronous
			// tasks have been completed
			for _ in 0..<asyncTaskCount {
				semaphore.wait()
			}
			
			// print("Parsed input: \(values)")
			switch values.count {
				case 0: then(.none)
				case 1: then(values.first!)
				default: then(.compound(values))
			}
		}
	}
}