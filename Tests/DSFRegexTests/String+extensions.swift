//
//  String+extensions.swift
//
//  Created by Darren Ford on 6/4/20.
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
