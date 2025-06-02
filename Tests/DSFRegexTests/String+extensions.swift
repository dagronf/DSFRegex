//
//  Copyright © 2025 Darren Ford. All rights reserved.
//
//  MIT license
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

//  Lazy extensions for Swift Strings indexing

import Foundation

extension String {
	func substring(_ range: Range<Int>) -> String {
		return String(self[self.range(range)])
	}

	func substring(_ range: PartialRangeFrom<Int>) -> String {
		return String(self[self.range(range)])
	}

	func substring(_ range: PartialRangeUpTo<Int>) -> String {
		return String(self[self.range(range)])
	}

	func substring(_ range: PartialRangeThrough<Int>) -> String {
		return String(self[self.range(range)])
	}

	func range(_ range: Range<Int>) -> Range<String.Index> {
		let si = self.index(self.startIndex, offsetBy: range.lowerBound)
		let ei = self.index(self.startIndex, offsetBy: range.upperBound)
		return si ..< ei
	}

	func range(_ range: ClosedRange<Int>) -> ClosedRange<String.Index> {
		let si = self.index(self.startIndex, offsetBy: range.lowerBound)
		let ei = self.index(self.startIndex, offsetBy: range.upperBound)
		return si ... ei
	}

	func range(_ partialRange: PartialRangeFrom<Int>) -> Range<String.Index> {
		let si = self.index(self.startIndex, offsetBy: partialRange.lowerBound)
		return si ..< self.endIndex
	}

	func range(_ partialRange: PartialRangeThrough<Int>) -> Range<String.Index> {
		let ei = self.index(self.startIndex, offsetBy: partialRange.upperBound + 1)
		return self.startIndex ..< ei
	}

	func range(_ partialRange: PartialRangeUpTo<Int>) -> Range<String.Index> {
		let ei = self.index(self.startIndex, offsetBy: partialRange.upperBound)
		return self.startIndex ..< ei
	}
}
