//
//  MIT License
//
//  Copyright (c) 2020 Darren Ford
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// A regex class wrapper for Swift
public class DSFRegex {
	private let _regex: NSRegularExpression

	/// The match pattern used to create the regex
	public var pattern: String {
		return _regex.pattern
	}

	/// Initialize a DSFRegex object with the specified parameters
	/// - Parameters:
	///   - pattern: The regular expression pattern to compile.
	///   - options: The regular expression options that are applied to the expression during matching. See NSRegularExpression.Options for possible values.
	/// - Throws: Any error (NSError) encountered if the regular expression pattern is invalid
	public init(_ pattern: String, options: NSRegularExpression.Options = []) throws {
		_regex = try NSRegularExpression(pattern: pattern, options: options)
	}

	/// Return true if the input text contains a match for the pattern, false otherwise
	/// - Parameters:
	///   - text: The input text to be searched
	///   - options: The regex options to use when matching
	/// - Returns: true if a match was found, false otherwise
	///
	/// This function is MUCH faster than the `matches` function as it terminates as soon as it finds a match.
	///
	/// If you only care about if it matches, and not _where_ it matches or capture groups, then use this
	public func matches(in text: String, options: NSRegularExpression.MatchingOptions = []) -> Bool {
		_regex.firstMatch(in: text, options: options, range: NSRange(text.startIndex..., in: text)) != nil
	}

	/// Return all the match information
	/// - Parameters:
	///   - text: The input text to be searched
	///   - options: The regex options to use when matching
	/// - Returns: a structure containing all of the matches and capture groups for those matches
	public func allMatches(in text: String, options: NSRegularExpression.MatchingOptions = []) -> Matches {
		let results = _regex.matches(
			in: text,
			options: options,
			range: NSRange(text.startIndex..., in: text)
		)

		let res = results.map { Match(result: $0, in: text) }
		return Matches(text: text, pattern: _regex.pattern, match: res)
	}
}

public extension DSFRegex {
	/// Return a new string containing matching regular expressions replaced with the template string.
	/// - Parameters:
	///   - text: The string to search for values within.
	///   - templ: The substitution template used when replacing matching instances.
	///   - range: The range of the string to search.
	///   - options: The matching options to use. See NSRegularExpression.MatchingOptions for possible values
	/// - Returns: A string with matching regular expressions replaced by the template string.
	///
	/// It's important to make sure that the replacement template is escaped correctly when replacing.
	/// NSRegularExpression provides a function to escape the replacement string correctly
	///
	/// `NSRegularExpression.escapedTemplate(for: str)`
	func stringByReplacingMatches(in text: String, withTemplate templ: String, range: Range<String.Index>? = nil, options: NSRegularExpression.MatchingOptions = []) -> String {
		let replaceRange: NSRange
		if let r = range {
			replaceRange = NSRange(r, in: text)
		} else {
			replaceRange = NSRange(text.startIndex..., in: text)
		}

		return _regex.stringByReplacingMatches(
			in: text,
			options: options,
			range: replaceRange,
			withTemplate: templ
		)
	}
}

// MARK: - Matches

public extension DSFRegex {
	/// Structure storing the results of a regex match on a string
	struct Matches {
		/// The text used when creating the matches
		let text: String

		/// A range that represents the entire range for the input search text
		var textRange: Range<String.Index> { return text.startIndex ..< text.endIndex }

		/// The regex pattern that was used to create the match result
		let pattern: String

		/// The array of matches found
		let match: [Match]

		/// The number of matches found for the search
		var numberOfMatches: Int { return self.match.count }

		/// Were there any matches found?
		var isEmpty: Bool { return self.numberOfMatches == 0 }

		/// Returns the match relating to the index offset. Matches found are in order that they are found in the input text
		subscript(index: Int) -> Match {
			assert(index < self.match.count)
			return match[index]
		}

		/// Did the regex match the input text completely? ie. number of matches == 1 AND the match range is equal to the input text range
		var isExactMatch: Bool {
			if self.numberOfMatches != 1 {
				return false
			}
			return self.match[0].range == self.textRange
		}
	}
}

// MARK: Text retrieval methods

public extension DSFRegex.Matches {
	/// Returns the text for the specified match
	func text(for match: DSFRegex.Match) -> String {
		if match.range.isEmpty { return "" }
		return String(self.text[match.range])
	}

	/// Returns the text captured for a capture
	func text(for capture: DSFRegex.Capture) -> String {
		if capture.isEmpty { return "" }
		return String(self.text[capture])
	}

	/// Returns an array of strings for each capture
	func text(for captures: [DSFRegex.Capture]) -> [String] {
		return captures.map { self.text(for: $0) }
	}

	/// Returns a string array containing the values for each capture in the match
	func text(forCapturesIn match: DSFRegex.Match) -> [String] {
		return self.text(for: match.capture)
	}
}

// MARK: Iterator support

/// Extension to allow conformance to sequence, so that you can do `for match in result { $0 ... }`
extension DSFRegex.Matches: Sequence {
	public func makeIterator() -> MatchIterator {
		return MatchIterator(matches: self.match)
	}

	/// Iterator to allow matches to be iterated over
	public struct MatchIterator: IteratorProtocol {
		public typealias Element = DSFRegex.Match

		let matches: [DSFRegex.Match]
		var offset: Int = 0

		public mutating func next() -> DSFRegex.Match? {
			if offset < matches.count {
				let m1 = matches[offset]
				offset += 1
				return m1
			}
			return nil
		}
	}
}

// MARK: - Match

public extension DSFRegex {
	struct Match {
		/// The match range within the search text.
		let range: Range<String.Index>

		/// The captures that were found as part of the search
		let capture: [Capture]

		init(result: NSTextCheckingResult, in text: String) {
			let matchRange = result.range(at: 0)
			range = Range(matchRange, in: text)!
			var captures = [Capture]()
			for count in 1 ..< result.numberOfRanges {
				let r = result.range(at: count)
				if r.location != NSNotFound, let textRange = Range(r, in: text) {
					captures.append(textRange as Capture)
				} else {
					// An empty capture result (for example, matching on (\+-)?(\\d)* with text '1234')
					captures.append(DSFRegex.Capture.empty)
				}
			}
			capture = captures
		}
	}
}

// MARK: - Capture

public extension DSFRegex {
	/// A range in the string representing a capture
	typealias Capture = Range<String.Index>
}

// Simple extension to provide a static 'empty' range

private extension DSFRegex.Capture {
	/// An empty capture object.
	static var empty: Range<String.Index> = "".startIndex ..< "".endIndex
}
