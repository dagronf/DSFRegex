//
//  String+CursorExtensions.swift
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

// MARK: - String Regex Cursor

public extension DSFRegex {
	/// A string cursor is useful when you are searching sporadically within a string, say in response to a user
	/// clicking on the 'next' button.  The cursor keeps track of the current match, and is used when locating the
	/// next match in the string.
	struct Cursor {
		// The regex to use to search
		internal let regex: DSFRegex
		// Any options to apply during the search
		internal let matchingOptions: NSRegularExpression.MatchingOptions

		/// The current match for the cursor
		public let match: DSFRegex.Match

		/// Return the range for the current match
		@inlinable public var range: Range<String.Index> {
			return self.match.range
		}

		/// Return the range for the current match as an NSRange for the specified string
		@inlinable public func nsRange(_ text: String) -> NSRange {
			return NSRange(self.range, in: text)
		}

		@inlinable func describeRange(in string: String) {
			Swift.print("\(self.nsRange(string)) -> '\(string[self.match.range])'")
		}
	}
}

public extension String {
	/// Find the first match for a regex within the string and returning a continue cursor
	/// - Parameters:
	///   - regex: The regular expression to match against
	///   - startIndex: (optional) the starting index in string to start searching from. If not supplied, starts searching from the beginning of the string
	///   - options: (optional) any options for the regular expression
	/// - Returns: A cursor object containing the match if a match is found, nil if no match was found.
	func firstMatch(
		for regex: DSFRegex,
		startingAt startIndex: String.Index? = nil,
		options: NSRegularExpression.MatchingOptions = []
	) -> DSFRegex.Cursor? {
		let start: String.Index = {
			if let s = startIndex {
				return s
			}
			else {
				return self.startIndex
			}
		}()

		guard start < self.endIndex else {
			return nil
		}

		if let match = regex.firstMatch(in: self, range: start ..< self.endIndex, options: options) {
			return DSFRegex.Cursor(regex: regex, matchingOptions: options, match: match)
		}
		return nil
	}

	/// Find the next match for the regex cursor
	/// - Parameters:
	///   - cursor: The cursor containing the previous match information
	///   - loop: If true, when no more matches are found in the string returns to the start of the string
	///   - startIndex: (optional) the starting index in string to start searching from. If not supplied, starts searching after the visitor's match
	///
	/// - Returns: A cursor object containing the match if a match is found, nil if no match was found.
	func nextMatch(
		for cursor: DSFRegex.Cursor,
		loop: Bool = false,
		startingAt startIndex: String.Index? = nil
	) -> DSFRegex.Cursor? {
		let start: String.Index = {
			if let s = startIndex {
				return s
			}
			else {
				return cursor.match.range.upperBound
			}
		}()

		guard start < self.endIndex else {
			return nil
		}

		if let match = cursor.regex.firstMatch(
			in: self,
			range: start ..< self.endIndex,
			options: cursor.matchingOptions
		) {
			return DSFRegex.Cursor(regex: cursor.regex, matchingOptions: cursor.matchingOptions, match: match)
		}
		else if loop {
			return self.firstMatch(for: cursor.regex, options: cursor.matchingOptions)
		}
		return nil
	}
}
