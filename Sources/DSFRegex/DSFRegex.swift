//
//  DSFRegex.swift
//
//  Copyright © 2023 Darren Ford. All rights reserved.
//
//  MIT License
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
	/// Regex errors
	enum RegexError: Error {
		/// An invalid range was specified (zero length or outside the bounds of the input string)
		case invalidRange
	}
	
	private let _regex: NSRegularExpression
	
	/// The match pattern used to create the regex
	public var pattern: String {
		return self._regex.pattern
	}
	
	/// Initialize a DSFRegex object with the specified parameters
	/// - Parameters:
	///   - pattern: The regular expression pattern to compile.
	///   - options: The regular expression options that are applied to the expression during matching. See NSRegularExpression.Options for possible values.
	/// - Throws: Any error (NSError) encountered if the regular expression pattern is invalid
	public init(_ pattern: String, options: NSRegularExpression.Options = []) throws {
		self._regex = try NSRegularExpression(pattern: pattern, options: options)
	}
	
	/// Return true if the input text contains a match for the pattern, false otherwise
	/// - Parameters:
	///   - text: The input text to be searched
	///   - range: The range of the input text to be searched (optional)
	///   - options: The regex options to use when matching (optional)
	/// - Returns: true if a match was found, false otherwise
	///
	/// This function is MUCH faster than the `matches` function as it terminates as soon as it finds a match.
	///
	/// If you only care about if it matches, and not _where_ it matches or capture groups, then use this
	public func hasMatch(_ text: String, range: Range<String.Index>? = nil, options: NSRegularExpression.MatchingOptions = []) -> Bool {
		let searchRange: Range<String.Index> = range ?? (text.startIndex ..< text.endIndex)
		let nsRange = NSRange(searchRange, in: text)
		return self._regex.firstMatch(in: text, options: options, range: nsRange) != nil
	}
	
	/// Return the first match within a given string, or nil if no match was found
	/// - Parameters:
	///   - text: The input text to be searched
	///   - range: The range of the input text to be searched (optional)
	///   - options: The regex options to use when matching (optional)
	/// - Returns: match information for the first match found, or nil if no matches were found
	public func firstMatch(in text: String, range: Range<String.Index>? = nil, options: NSRegularExpression.MatchingOptions = []) -> Match? {
		let searchRange: Range<String.Index> = range ?? (text.startIndex ..< text.endIndex)
		let nsRange = NSRange(searchRange, in: text)
		guard let match = _regex.firstMatch(in: text, options: options, range: nsRange) else {
			return nil
		}
		return try? Match(result: match, in: text)
	}
	
	/// Return all match information
	/// - Parameters:
	///   - text: The input text to be searched
	///   - range: The range of the input text to be searched (optional)
	///   - options: The regex options to use when matching (optional)
	/// - Returns: a structure containing all of the matches and capture groups for those matches
	public func matches(for text: String, range: Range<String.Index>? = nil, options: NSRegularExpression.MatchingOptions = []) -> Matches {
		let searchRange: Range<String.Index> = range ?? (text.startIndex ..< text.endIndex)
		let nsRange = NSRange(searchRange, in: text)
		let results = self._regex.matches(in: text, options: options, range: nsRange)
		let res = results.compactMap { try? Match(result: $0, in: text) }
		return Matches(text: text, pattern: self._regex.pattern, matches: res)
	}
	
	/// Return all match information from a specific index to the end of the string
	/// - Parameters:
	///   - text: The input text to be searched
	///   - rangeFrom: The partial range of the input text to be searched.
	///   - options: The regex options to use when matching (optional)
	/// - Returns: a structure containing all of the matches and capture groups for those matches within the specified range
	public func matches(for text: String, rangeFrom: PartialRangeFrom<String.Index>, options: NSRegularExpression.MatchingOptions = []) -> Matches {
		guard rangeFrom.lowerBound < text.endIndex else {
			fatalError("Invalid Range")
		}
		let searchRange: Range<String.Index> = rangeFrom.lowerBound ..< text.endIndex
		return self.matches(for: text, range: searchRange, options: options)
	}
	
	/// Return all match information from the start of the string to a specific index
	/// - Parameters:
	///   - text: The input text to be searched
	///   - rangeUpTo: The partial range of the input text to be searched.
	///   - options: The regex options to use when matching (optional)
	/// - Returns: a structure containing all of the matches and capture groups for those matches within the specified range
	public func matches(for text: String, rangeUpTo: PartialRangeUpTo<String.Index>, options: NSRegularExpression.MatchingOptions = []) -> Matches {
		let searchRange: Range<String.Index> = text.startIndex ..< rangeUpTo.upperBound
		return self.matches(for: text, range: searchRange, options: options)
	}
	
	/// Return all match information from the start of the range up to, and including, the last character in the range.
	/// - Parameters:
	///   - text: The input text to be searched
	///   - rangeTo: The partial range of the input text to be searched.
	///   - options: The regex options to use when matching (optional)
	/// - Returns: a structure containing all of the matches and capture groups for those matches within the specified range
	public func matches(for text: String, rangeUpToIncluding: PartialRangeThrough<String.Index>, options: NSRegularExpression.MatchingOptions = []) -> Matches {
		// Move beyond the last character
		let upperBound = text.index(rangeUpToIncluding.upperBound, offsetBy: 1)
		let searchRange: Range<String.Index> = text.startIndex ..< upperBound
		return self.matches(for: text, range: searchRange, options: options)
	}
	
	/// Enumerate through the matches in the provided text. Useful if you have a large or complex regex and/or text
	/// - Parameters:
	///   - text: The text to search
	///   - range: (optional) the range of `text` to search within
	///   - progress: (optional) a block to report progress during a long-running match operation. If this block returns false, cancels the enumeration
	///   - matchBlock: The block to call when a match is found. If this block returns false, cancels the enumeration
	public func enumerateMatches(
		in text: String,
		range: Range<String.Index>? = nil,
		progress: (() -> Bool)? = nil,
		_ matchBlock: @escaping (Match) -> Bool
	) {
		let searchRange: Range<String.Index> = range ?? (text.startIndex ..< text.endIndex)
		let nsRange = NSRange(searchRange, in: text)
		
		let options: NSRegularExpression.MatchingOptions =
		(progress != nil) ? [.reportProgress, .reportCompletion] : [.reportCompletion]
		
		self._regex.enumerateMatches(in: text, options: options, range: nsRange) { textCheckingResult, flags, stop in
			guard let check = textCheckingResult else {
				if flags.contains(.progress),
					let p = progress, p() == false
				{
					// User has specified a progress callback and the progress block returned false
					stop.pointee = true
				}
				return
			}
			
			guard let match = try? Match(result: check, in: text) else {
				// Couldn't map an NSRange back into our original string. Very odd! Just ignore.
				Swift.print("WARNING: Unable to map range into input text")
				return
			}
			
			if matchBlock(match) == false {
				stop.pointee = true
			}
		}
	}
}

public extension DSFRegex {
	/// Return a new string containing matching regular expressions replaced with the template string.
	/// - Parameters:
	///   - text: The string to search for values within.
	///   - escapedTemplate: The substitution template used when replacing matching instances.
	///   - range: The range of the string to search.
	///   - options: The matching options to use. See NSRegularExpression.MatchingOptions for possible values
	/// - Returns: A string with matching regular expressions replaced by the template string.
	///
	/// It's important to make sure that the replacement template is escaped correctly when replacing.
	/// NSRegularExpression provides a function to escape the replacement string correctly
	///
	/// `NSRegularExpression.escapedTemplate(for: str)`
	///
	/// If you don't want to reuse the escaped template, you should use the `stringByReplacingMatches(in:with:range:options:)` method instead
	func stringByReplacingMatches(in text: String, withEscapedTemplateString escapedTemplate: String, range: Range<String.Index>? = nil, options: NSRegularExpression.MatchingOptions = []) -> String {
		let searchRange: Range<String.Index> = range ?? (text.startIndex ..< text.endIndex)
		let nsRange = NSRange(searchRange, in: text)
		return self._regex.stringByReplacingMatches(
			in: text,
			options: options,
			range: nsRange,
			withTemplate: escapedTemplate
		)
	}
	
	/// Return a new string containing matching regular expressions replaced with the template string.
	/// - Parameters:
	///   - text: The string to search for values within.
	///   - string: The substitution template used when replacing matching instances.
	///   - range: The range of the string to search.
	///   - options: The matching options to use. See NSRegularExpression.MatchingOptions for possible values
	/// - Returns: A string with matching regular expressions replaced by the template string.
	///
	/// This method automatically escapes 'string' during execution so that it is safe to use as a replacement string.
	func stringByReplacingMatches(in text: String, with string: String, range: Range<String.Index>? = nil, options: NSRegularExpression.MatchingOptions = []) -> String {
		let searchRange: Range<String.Index> = range ?? (text.startIndex ..< text.endIndex)
		let nsRange = NSRange(searchRange, in: text)
		let templateString = NSRegularExpression.escapedTemplate(for: string)
		return self._regex.stringByReplacingMatches(
			in: text,
			options: options,
			range: nsRange,
			withTemplate: templateString
		)
	}
}

// MARK: - Matches

public extension DSFRegex {
	/// Structure storing the results of a regex match on a string
	struct Matches {
		/// The text used when creating the matches
		public let text: String
		
		/// A range that represents the entire range for the input search text
		public var textRange: Range<String.Index> { return self.text.startIndex ..< self.text.endIndex }
		
		/// The regex pattern that was used to create the match result
		public let pattern: String
		
		/// The array of matches found
		public let matches: [Match]
		
		/// The number of matches found for the search
		public var count: Int { return self.matches.count }
		
		/// Were there any matches found?
		public var isEmpty: Bool { return self.count == 0 }
		
		/// Returns the match relating to the index offset. Matches found are in order that they are found in the input text
		public subscript(index: Int) -> Match {
			assert(index < self.matches.count)
			return self.matches[index]
		}
		
		/// Did the regex match the input text completely? ie. number of matches == 1 AND the match range is equal to the input text range
		public var isExactMatch: Bool {
			if self.count != 1 {
				return false
			}
			return self.matches[0].range == self.textRange
		}
	}
}

// MARK: Text retrieval methods

public extension DSFRegex.Matches {
	/// Returns the text for each of the matches
	func textMatching() -> [String] {
		return self.matches.map { self.text(for: $0) }
	}
	
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
	
	/// Returns a string array containing the values for each capture in the input array
	/// - Parameter captures: the captures to retrieve strings for
	/// - Returns: an array of capture strings
	func text(for captures: [DSFRegex.Capture]) -> [String] {
		return captures.map { self.text(for: $0) }
	}
	
	/// Returns a string array containing the values for each capture in a match
	/// - Parameter match: the match to retrieve capture string from
	/// - Returns: an array of the capture strings for the match
	func text(forCapturesIn match: DSFRegex.Match) -> [String] {
		return self.text(for: match.captures)
	}
	
	/// Returns the string for a match
	/// - Parameter match: index of the match to retrieve
	/// - Returns: a string containing the text of the match
	func text(match: Int) -> String {
		assert(match < self.matches.count)
		let match = self.matches[match]
		return self.text(for: match)
	}
	
	/// Returns the string for the capture in the specified match
	/// - Parameters:
	///   - match: index of the match to retrieve
	///   - capture: index of the capture within the match to retrieve
	/// - Returns: a string containing the text of the match for the capture
	func text(match: Int, capture: Int) -> String {
		assert(match < self.matches.count)
		assert(capture < self.matches[match].captures.count)
		let capture = self.matches[match].captures[capture]
		return self.text(for: capture)
	}
}

// MARK: Iterator support

extension DSFRegex.Matches: Sequence {
	/// Extension to allow conformance to sequence, so that you can do `for match in result { $0 ... }`
	public func makeIterator() -> MatchIterator {
		return MatchIterator(matches: self.matches)
	}
	
	/// Iterator to allow matches to be iterated over
	public struct MatchIterator: IteratorProtocol {
		public typealias Element = DSFRegex.Match
		
		let matches: [DSFRegex.Match]
		var offset = 0
		
		public mutating func next() -> DSFRegex.Match? {
			if self.offset < self.matches.count {
				let m1 = self.matches[self.offset]
				self.offset += 1
				return m1
			}
			return nil
		}
	}
}

// MARK: - Match

public extension DSFRegex {
	/// Represent a match within the regex results.
	struct Match {
		/// The match range within the search text.
		public let range: Range<String.Index>
		
		/// The captures that were found as part of the search
		public let captures: [Capture]
		
		init(result: NSTextCheckingResult, in text: String) throws {
			let matchRange = result.range(at: 0)
			guard let mr = Range(matchRange, in: text) else {
				throw RegexError.invalidRange
			}
			self.range = mr
			
			var captures = [Capture]()
			for count in 1 ..< result.numberOfRanges {
				let r = result.range(at: count)
				if r.location != NSNotFound, let textRange = Range(r, in: text) {
					captures.append(textRange as Capture)
				}
				else {
					// An empty capture result (for example, matching on (\+-)?(\\d)* with text '1234')
					captures.append(DSFRegex.Capture.empty)
				}
			}
			self.captures = captures
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
	static var empty = "".startIndex ..< "".endIndex
}

// MARK: - String extensions

public extension String {
	/// Return true if the input text contains a match for the pattern, false otherwise
	/// - Parameters:
	///   - regex: The regex to perform matches with
	/// - Returns: true if a match was found, false otherwise
	func hasMatch(_ regex: DSFRegex) -> Bool {
		return regex.hasMatch(self)
	}
	
	/// Return all match information for the current string and the specified regex
	/// - Parameters:
	///   - regex: The regex to perform matches with
	/// - Returns: a structure containing all of the matches and capture groups for those matches
	func matches(for regex: DSFRegex) -> DSFRegex.Matches {
		return regex.matches(for: self)
	}
}
