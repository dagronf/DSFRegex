//
//  ViewController.swift
//  Regex Find Demo
//
//  Created by Darren Ford on 7/4/20.
//  Copyright © 2020 Darren Ford. All rights reserved.
//

import DSFRegex
import UIKit

class ViewController: UIViewController {
	@IBOutlet var textView: UITextView!
	@IBOutlet var searchField: UITextField!
	@IBOutlet weak var currentMatchButton: UIButton!
	@IBOutlet weak var previousButton: UIButton!
	@IBOutlet weak var nextButton: UIButton!

	@IBOutlet weak var matchText: UITextView!

	var currentMatch: Int = -1
	var searchResults: DSFRegex.Matches!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		do {
			let pth = Bundle.main.path(forResource: "alice-in-wonderland", ofType: "txt")!
			let upth = URL(fileURLWithPath: pth)
			let str = try String(contentsOf: upth, encoding: .utf8)

			textView.text = str
		} catch {
			fatalError()
		}

		self.matchText.text = ""
		self.currentMatchButton.setTitle("", for: .normal)

		self.syncButtons()
	}

	func syncButtons() {
		let enabled = self.searchResults != nil
		self.previousButton.isEnabled = enabled
		self.nextButton.isEnabled = enabled
	}

	@IBAction func performSearch(_: Any) {
		textView.textStorage.removeAttribute(
			.backgroundColor,
			range: NSRange(location: 0, length: textView.textStorage.length)
		)

		self.matchText.text = ""
		//self.currentMatchButton.setTitle("", for: .normal)

		guard let pattern = searchField.text else {
			return
		}

		guard let regex = try? DSFRegex(pattern) else {
			return
		}

		textView.textStorage.beginEditing()

		self.currentMatch = -1
		self.searchResults = nil

		let color = UIColor(named: "TextHightlight")!

		self.searchResults = regex.matches(for: textView.text)
		for match in self.searchResults {
			let nsRange = NSRange(match.range, in: textView.text)
			textView.textStorage.addAttribute(.backgroundColor, value: color, range: nsRange)
		}
		textView.textStorage.endEditing()

		// Go to the first one
		if self.searchResults.count > 0 {
			self.currentMatch = 0
			self.highlightCurrent()
		}

		self.syncButtons()
	}

	func highlightCurrent() {

		if self.searchResults == nil {
			self.currentMatchButton.setTitle("", for: .normal)

			return
		}

		self.textView.becomeFirstResponder()

		guard self.currentMatch < self.searchResults.count else {
			return
		}

		let nsRange = NSRange(self.searchResults[self.currentMatch].range, in: self.textView.text)

		self.textView.scrollRangeToVisible(nsRange)
		self.textView.selectedRange = nsRange
		UIView.performWithoutAnimation {
			self.currentMatchButton.setTitle("\(self.currentMatch + 1) / \(self.searchResults.count)", for: .normal)
		}

		self.updateMatch()
	}

	@IBAction func nextMatch(_ sender: Any) {
		self.currentMatch += 1
		if self.currentMatch >= self.searchResults.count {
			self.currentMatch = 0
		}
		self.highlightCurrent()
	}

	@IBAction func previousMatch(_ sender: Any) {
		self.currentMatch -= 1
		if self.currentMatch < 0 {
			self.currentMatch = self.searchResults.count - 1
		}
		self.highlightCurrent()
	}

	@IBAction func currentMatch(_ sender: Any) {
		self.highlightCurrent()
	}
}

extension ViewController {
	func updateMatch() {
		guard let results = self.searchResults else {
			return
		}

		let expansionSize = 50

		let match = results.matches[self.currentMatch]
		let text = self.textView.text ?? ""

		let nsFullRange = NSRange(text.startIndex ..< text.endIndex, in: text)
		let nsLength = nsFullRange.length

		let nsMatchRange = NSRange(match.range, in: text)
		let matchText = text[match.range]

		var leftRange = nsMatchRange
		let origLeftLoc = leftRange.location
		leftRange.location = max(0, leftRange.location - expansionSize)
		leftRange.length = min(expansionSize, origLeftLoc - leftRange.location)
		let leftR = Range(leftRange, in: text)!
		let prefix = String(text[ leftR ])
		let prefixPrior = leftRange.location == 0 ? "" : "…"

		var postfixPost: String = "…"
		var rightRange = nsMatchRange
		rightRange.location = nsMatchRange.location + nsMatchRange.length
		rightRange.length = expansionSize
		if rightRange.location + rightRange.length > nsLength {
			rightRange.length = nsLength - rightRange.location
			postfixPost = ""
		}
		let rightR = Range(rightRange, in: text)!
		let postfix = String(text[ rightR ])

		let attributedString = NSAttributedString.stream {
			$0.set([.underlineStyle: NSUnderlineStyle.single.rawValue])
				.set(.boldSystemFont(ofSize: 15))
				.set(.label)
				.append("Match \(nsMatchRange)\n\n")
				.unset(.underlineStyle)
				.set(.systemFont(ofSize: 15))

			$0.set(.placeholderText)
				.append("\(prefixPrior)\(prefix)")

			$0.set(.label)
				.set(.boldSystemFont(ofSize: 15))
				.append("\(matchText)")

			$0.set(.placeholderText)
				.set(.systemFont(ofSize: 15))
				.append("\(postfix)\(postfixPost)")

			$0.set([.underlineStyle: NSUnderlineStyle.single.rawValue])
				.set(.label)
				.set(.boldSystemFont(ofSize: 15))
				.append("\n\nCaptures: \(match.captures.count)\n")
				.unset(.underlineStyle)

			for capture in match.captures.enumerated() {
				let captureText = text[capture.element]

				$0.set(.boldSystemFont(ofSize: 15))
				$0.append("\nCapture \(capture.offset + 1): ")
				$0.set(.systemFont(ofSize: 15))
				$0.append("\(captureText)")
			}
		}

		self.matchText.attributedText = attributedString
	}
}


extension ViewController: UITextViewDelegate {
	func textViewDidChange(_ textView: UITextView) {
		guard self.searchResults != nil else {
			return
		}

		self.searchResults = nil
		self.textView.textStorage.removeAttribute(
			.backgroundColor,
			range: NSRange(location: 0, length: textView.textStorage.length)
		)
		self.highlightCurrent()
		self.syncButtons()
	}
}
