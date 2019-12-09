import Foundation

fileprivate let asciiCharacters = CharacterSet(charactersIn: " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~")
fileprivate let quotes = CharacterSet(charactersIn: "\"'`")

extension StringProtocol {
	public func split(by length: Int) -> [String] {
		var start = startIndex
		var output = [String]()
		
		while start < endIndex {
			let end = index(start, offsetBy: length, limitedBy: endIndex) ?? endIndex
			output.append(String(self[start..<end]))
			start = end
		}
		
		return output
	}
	
	public func splitPreservingQuotes(by separator: Character, omitQuotes: Bool = false, omitBackslashes: Bool = false) -> [String] {
		var split = [String]()
		var segment = ""
		var quoteStack = [Character]()
		var last: Character? = nil
		for c in self {
			if quoteStack.isEmpty && c == separator {
				print("Adding \(segment)")
				split.append(segment)
				segment = ""
			} else {
				let isQuote = c.unicodeScalars.first.map { quotes.contains($0) } ?? false
				let isEscaped = last == "\\"
				
				if isQuote && !isEscaped {
					if let quote = quoteStack.last, quote == c {
						quoteStack.removeLast()
					} else {
						quoteStack.append(c)
					}
				}
				
				if isEscaped && omitBackslashes {
					segment.removeLast()
				}

				if !omitQuotes || !isQuote || isEscaped {
					segment.append(c)
				}
			}
			last = c
		}
		split.append(segment)
		return split
	}
	
	public var asciiOnly: String? {
		return components(separatedBy: asciiCharacters).joined()
	}
	
	public var nilIfEmpty: Self? {
		return isEmpty ? nil : self
	}
	
	public var isAlphabetic: Bool {
		for scalar in unicodeScalars {
			if !CharacterSet.letters.contains(scalar) {
				return false
			}
		}
		return true
	}
	
	public func truncate(_ length: Int, appending trailing: String = "") -> String {
		if count > length {
			return prefix(length) + trailing
		} else {
			return String(self)
		}
	}
}
