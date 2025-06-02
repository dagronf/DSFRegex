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

@testable import DSFRegex
import XCTest

final class DSFRegexTests: XCTestCase {

	lazy var EmailRegex: DSFRegex = {
		let emailAddressRegex = #"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])"#
		guard let r = try? DSFRegex(emailAddressRegex, options: .caseInsensitive) else {
			fatalError("Unable to create email regex")
		}
		return r
	}()

	func testThrowConstructor() {

		// Invalid regular expression: /(?<={index:)\d+(?=})/: Invalid group
		XCTAssertThrowsError(try DSFRegex(#"(?<={index:)\d+(?=})"#))
	}

	func testPhoneMatches() throws {
		let phoneNumberRegex = try DSFRegex(#"(\d{4})-(\d{3})-(\d{3})"#)

		XCTAssertTrue(phoneNumberRegex.hasMatch("3499-999-999"))
		XCTAssertFalse(phoneNumberRegex.hasMatch("3499 999-999"))

		let resultMatches = phoneNumberRegex.matches(for: "4499-999-888 4491-111-444 4324-222-123")
		XCTAssertEqual(3, resultMatches.count)

		XCTAssertEqual("4499-999-888", resultMatches.text(for: resultMatches[0]))
		XCTAssertEqual("4491-111-444", resultMatches.text(for: resultMatches[1]))
		XCTAssertEqual("4324-222-123", resultMatches.text(for: resultMatches[2]))

		XCTAssertEqual(["4499", "999", "888"], resultMatches.text(forCapturesIn: resultMatches[0]))
		XCTAssertEqual(["4491", "111", "444"], resultMatches.text(forCapturesIn: resultMatches[1]))
		XCTAssertEqual(["4324", "222", "123"], resultMatches.text(forCapturesIn: resultMatches[2]))

		XCTAssertEqual("4499", resultMatches.matches[0].captureString(for: 0))
		XCTAssertEqual("999", resultMatches.matches[0].captureString(for: 1))
		XCTAssertEqual("888", resultMatches.matches[0].captureString(for: 2))

		XCTAssertEqual(["4499", "999", "888"], resultMatches.matches[0].captureStrings())

		XCTAssertEqual("4324", resultMatches.matches[2].captureString(for: 0))
		XCTAssertEqual("222", resultMatches.matches[2].captureString(for: 1))
		XCTAssertEqual("123", resultMatches.matches[2].captureString(for: 2))
		XCTAssertEqual(["4324", "222", "123"], resultMatches.matches[2].captureStrings())

		let textMatches = resultMatches.textMatching()
		XCTAssertEqual(["4499-999-888", "4491-111-444", "4324-222-123"], textMatches)

		for match in resultMatches.enumerated() {
			let matchText = resultMatches.text(for: match.element)
			Swift.print("Match (\(match.offset)) -> `\(matchText)`")
			for capture in match.element.captures.enumerated() {
				let captureText = resultMatches.text(for: capture.element)
				Swift.print("  Capture (\(capture.offset)) -> `\(captureText)`")
			}
		}

		let regex = try DSFRegex(#"([\+-]?)(\d+)(?:\.(\d+))?"#)
		let matches = regex.matches(for: "11.15 -9.942")
		XCTAssertEqual(matches.count, 2)

		// Get the text for the matches
		let matchText1 = matches.text(for: matches.matches[0])
		XCTAssertEqual("11.15", matchText1)
		let matchText2 = matches.text(for: matches.matches[1])
		XCTAssertEqual("-9.942", matchText2)

		// Get the contents of the capture groups for these matches
		let captureTexts1 = matches.text(forCapturesIn: matches.matches[0])
		XCTAssertEqual(["", "11", "15"], captureTexts1)
		let captureTexts2 = matches.text(forCapturesIn: matches.matches[1])
		XCTAssertEqual(["-", "9", "942"], captureTexts2)
	}

	func testSimpleMatchForeach() throws {
		let inputText = "1\t\"fred🌺dy\"\ndumမြန်မာအက္ခရာmy32\t\"noodle မြန်မာအက္ခရာ caterpillar\""

		// Build the regex to match against (in this case, <number>\t<string>)
		// This regex has two capture groups, one for the number and one for the string.
		let regex = try DSFRegex(#"(\d*)\t\"([^\"]+)\""#)

		// Retrieve ALL the matches for the supplied text
		let allMatches = regex.matches(for: inputText)

		// Loop over each of the matches found, and print them out
		var count = 0
		allMatches.forEach { match in
			let foundStr = inputText[match.range]          // The text of the entire match
			let numberVal = inputText[match.captures[0]]   // Retrieve the first capture group text.
			let stringVal = inputText[match.captures[1]]   // Retrieve the second capture group text.

			switch count {
			case 0:
				XCTAssertEqual(foundStr, "1\t\"fred🌺dy\"")
				XCTAssertEqual(numberVal, "1")
				XCTAssertEqual(stringVal, "fred🌺dy")
			case 1:
				XCTAssertEqual(foundStr, "32\t\"noodle မြန်မာအက္ခရာ caterpillar\"")
				XCTAssertEqual(numberVal, "32")
				XCTAssertEqual(stringVal, "noodle မြန်မာအက္ခရာ caterpillar")
			default:
				XCTFail("Bad test")
			}
			count += 1
		}
	}

	func testNonCapture() throws {
		let r = try DSFRegex("(\\+|-)?([[:digit:]]+)")
		var results = r.matches(for: "bitter lemon")
		XCTAssertEqual(0, results.count)
		XCTAssertTrue(results.isEmpty)
		results = r.matches(for: "1234")
		XCTAssertEqual(1, results.count)
		XCTAssertFalse(results.isEmpty)

		// Note here that the capture group (\\+|-)? is optional -- the library
		// will add in a capture with an empty range to keep the capture group -> array position matching
		XCTAssertEqual(2, results[0].captures.count)
		XCTAssertTrue(results[0].captures[0].isEmpty)
		XCTAssertFalse(results[0].captures[1].isEmpty)

		results = r.matches(for: "-9870")
		XCTAssertEqual(1, results.count)

		// Note that the regex does not handle a fraction value - hence the . breaks the number into two
		results = r.matches(for: "-987.0")
		XCTAssertEqual(2, results.count)
		XCTAssertEqual("-", results.text(for: results.matches[0].captures[0]))
		XCTAssertEqual("987", results.text(for: results.matches[0].captures[1]))

		XCTAssertEqual("", results.text(for: results.matches[1].captures[0]))
		XCTAssertEqual("0", results.text(for: results.matches[1].captures[1]))
	}

	func testSimpleOne() throws {
		let r = try DSFRegex("(.*) [sS](\\d\\d)[eE](\\d\\d) - (.*)", options: .caseInsensitive)
		let results = r.matches(for: "ChoccyWokky s03e01 - Noodles.mp4")
		XCTAssertEqual(1, results.count)
		XCTAssertEqual(4, results[0].captures.count)
		XCTAssertEqual("ChoccyWokky", results.text(for: results[0].captures[0]))
		print(results)
	}

	func testSimpleTwo() throws {
		let r = try DSFRegex("(.*) [sS](\\d\\d)[eE](\\d\\d) - (.*)", options: .caseInsensitive)
		let results = r.matches(for: "ChoccyWokky s03e01 - Noodles.pdf\nChoccyWokky s03e02 - Caterpillar.pdf")
		XCTAssertEqual(2, results.count)

		XCTAssertFalse(results.isExactMatch)

		XCTAssertEqual(4, results[0].captures.count)
		let captures0 = results.text(forCapturesIn: results[0])
		XCTAssertEqual(["ChoccyWokky", "03", "01", "Noodles.pdf"], captures0)

		XCTAssertEqual(4, results[1].captures.count)
		let captures1 = results.text(for: results[1].captures)
		XCTAssertEqual(["ChoccyWokky", "03", "02", "Caterpillar.pdf"], captures1)

		// Just to check that this isn't being fudged
		XCTAssertNotEqual(["ChoccyWo2kky", "03", "02", "Caterpillar.pdf"], captures1)
	}

	func testFractional() throws {
		let r = try DSFRegex(#"([\+-]?)(\d+)(?:\.(\d+))?"#)

		// Simple fractional
		var results = r.matches(for: "11.15")

		XCTAssertEqual(1, results.count)
		XCTAssertEqual(3, results[0].captures.count)
		XCTAssertTrue(results[0].captures[0].isEmpty)
		XCTAssertEqual("", results.text(for: results[0].captures[0]))
		XCTAssertEqual("11", results.text(for: results[0].captures[1]))
		XCTAssertEqual("15", results.text(for: results[0].captures[2]))

		results = r.matches(for: "  11.15")
		XCTAssertEqual(1, results.count)
		XCTAssertTrue(results[0].captures[0].isEmpty)
		XCTAssertEqual("", results.text(for: results[0].captures[0]))
		XCTAssertEqual("11", results.text(for: results[0].captures[1]))
		XCTAssertEqual("15", results.text(for: results[0].captures[2]))

		results = r.matches(for: "  11.15 -22.4 +-2.4")
		XCTAssertEqual(3, results.count)

		results = r.matches(for: "-12345657.890")
		XCTAssertEqual(1, results.count)
		XCTAssertEqual("-", results.text(for: results[0].captures[0]))
		XCTAssertFalse(results[0].captures[0].isEmpty)
		XCTAssertEqual("12345657", results.text(for: results[0].captures[1]))
		XCTAssertEqual("890", results.text(for: results[0].captures[2]))

		XCTAssertEqual(#"([\+-]?)(\d+)(?:\.(\d+))?"#, r.pattern)
	}

	func testBrokenTwo() throws {
		let r = try DSFRegex("(.*) [sS](\\d\\d)[eE](\\d\\d) - (.*)", options: .caseInsensitive)
		let results = r.matches(for: "ChoccyWokky s03e01 - Noodles.mp4\nChoccyWokky s03d02 - Caterpillar.mp4")
		XCTAssertEqual(1, results.count)
		XCTAssertEqual(4, results[0].captures.count)
		print(results)
	}

	func testSequence() throws {
		let r = try DSFRegex("([\\+-]?)(\\d+)(?:\\.(\\d+))?")
		let results = r.matches(for: "  11.15 -22.4 +-2.4")
		XCTAssertEqual(3, results.count)
		for match in results.enumerated() {
			// ALL matches should have the same number of captures in their capture group,
			// even if some of them are empty
			XCTAssertEqual(3, match.element.captures.count)
			if match.offset == 0 {
				XCTAssertTrue(match.element.captures[match.offset].isEmpty)
			} else {
				XCTAssertFalse(match.element.captures[match.offset].isEmpty)
			}
		}
	}

	func testEmailValidation() throws {
		// Email regex from here -- https://emailregex.com
		let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

		// Test that there are matches.
		XCTAssertTrue(EmailRegex.hasMatch(inputString))

		let matches = EmailRegex.matches(for: inputString)
		XCTAssertEqual(2, matches.count)

		let email1 = matches.text(for: matches[0])
		XCTAssertEqual("noodles@compuserve4.nginix.com", email1)
		XCTAssertEqual(0, matches[0].captures.count)

		let email2 = matches.text(for: matches[1])
		XCTAssertEqual("sillytest32@gmail.com", email2)
		XCTAssertEqual(0, matches[1].captures.count)

		// Just return the email addresses
		let textMatches = matches.textMatching()
		XCTAssertEqual(["noodles@compuserve4.nginix.com", "sillytest32@gmail.com"], textMatches)
	}

	func testFirstMatch() throws {
		let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

		// Test that there are matches.
		XCTAssertTrue(EmailRegex.hasMatch(inputString))

		try scenario("Check that the first match is found") {
			let first = EmailRegex.firstMatch(in: inputString)
			XCTAssertNotNil(first)
			XCTAssertEqual("noodles@compuserve4.nginix.com", String(inputString[first!.range]))
		}

		try scenario("Check that if match is not found returns nil") {
			let noMatch = EmailRegex.firstMatch(in: "Sphinx of black quartz judge my vow")
			XCTAssertNil(noMatch)
		}

		try scenario("More checking against hex values") {
			let regex = try DSFRegex(#"#?([a-f0-9]{6}|[a-f0-9]{3})"#)
			let hexStrings = "#a3c113 #bad #noodle"

			let first = regex.firstMatch(in: hexStrings)
			XCTAssertNotNil(first)
			XCTAssertEqual("a3c113", hexStrings[first!.captures[0]])

			/// First match in a range which isn't the start
			let second = regex.firstMatch(in: hexStrings, range: hexStrings.range(5...))
			XCTAssertNotNil(second)
			XCTAssertEqual("bad", hexStrings[second!.captures[0]])

			let results = regex.matches(for: hexStrings)
			XCTAssertEqual(2, results.count)		// #noodle isn't a valid hex string
			XCTAssertEqual("a3c113", results.text(match: 0, capture: 0))
			XCTAssertEqual("bad", results.text(match: 1, capture: 0))
		}
	}

	func testStringReplacement() throws {
		let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

		try scenario("Verify that our regex matches two email addresses") {
			let matches = EmailRegex.matches(for: inputString)
			XCTAssertEqual(2, matches.count)

			XCTAssertEqual("noodles@compuserve4.nginix.com", matches.text(for: matches[0]))
			XCTAssertEqual("sillytest32@gmail.com", matches.text(for: matches[1]))
		}

		try scenario("Replace all the email addresses in a string with a replacement value") {
			let REDAC = "This is a test.\n <REDACTED-EMAIL-ADDRESS> and <REDACTED-EMAIL-ADDRESS> lives here"
			let redacted = EmailRegex.stringByReplacingMatches(
				in: inputString,
				with: "<REDACTED-EMAIL-ADDRESS>"
			)
			XCTAssertEqual(REDAC, redacted)
		}

		try scenario("Replace only the first one (index 52 is just after the 'and')") {
			let REDAC2 = "This is a test.\n <REDACTED-EMAIL-ADDRESS> and sillytest32@gmail.com lives here"
			let redacted2 = EmailRegex.stringByReplacingMatches(
				in: inputString,
				withEscapedTemplateString: NSRegularExpression.escapedTemplate(for: "<REDACTED-EMAIL-ADDRESS>"),
				range: inputString.range(0 ..< 52),
				options: []
			)
			XCTAssertEqual(REDAC2, redacted2)
		}

		try scenario("Replace only the second one (search only after the 30th character") {
			let REDAC2 = "This is a test.\n noodles@compuserve4.nginix.com and <REDACTED-EMAIL-ADDRESS> lives here"
			let redacted2 = EmailRegex.stringByReplacingMatches(
				in: inputString,
				with: "<REDACTED-EMAIL-ADDRESS>",
				range: inputString.range(30...),
				options: []
			)
			XCTAssertEqual(REDAC2, redacted2)
		}
	}

	func testExactMatch() throws {
		var matches = EmailRegex.matches(for: "noodles@compuserve4.nginix.com")
		XCTAssertEqual(1, matches.count)
		XCTAssertTrue(matches.isExactMatch)

		matches = EmailRegex.matches(for: "email - noodles@compuserve4.nginix.com")
		XCTAssertEqual(1, matches.count)
		XCTAssertFalse(matches.isExactMatch)

		matches = EmailRegex.matches(for: "noodles@compuserve4.nginix.com ")
		XCTAssertEqual(1, matches.count)
		XCTAssertFalse(matches.isExactMatch)
	}

	func testSearchInRange() throws {
		let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

		let matches = EmailRegex.matches(for: inputString)
		XCTAssertEqual(2, matches.count)

		XCTAssertTrue(EmailRegex.hasMatch(inputString))

		let noMatchRange = inputString.range(0 ..< 30)
		XCTAssertFalse(EmailRegex.hasMatch(inputString, range: noMatchRange))

		let range2Matches = EmailRegex.matches(for: inputString, range: noMatchRange)
		XCTAssertEqual(0, range2Matches.count)

		let firstCheckRange = inputString.range(0 ..< 52)
		let range1Matches = EmailRegex.matches(for: inputString, range: firstCheckRange)
		XCTAssertEqual(1, range1Matches.count)
	}

	func testUnicodeTests() throws {
		try scenario("Test that non-ascii character set can be matched") {
			let regex = try DSFRegex(#"^(?:[\p{L}\p{Mn}\p{Pd}\'\x{2019}]+\s[\p{L}\p{Mn}\p{Pd}\'\x{2019}]+\s?)+$"#)
			let matches = regex.matches(for: "John Elkjærd")
			XCTAssertEqual(1, matches.count)
			XCTAssertFalse(regex.hasMatch("H4nn3 Andersen"))
		}

		try scenario("A sub-range of chinese text can be matched correctly") {
			let regex = try DSFRegex(#"。(.*?)。"#)
			let inputString = #"中國4日舉行全國哀悼活動，追悼在新型冠病毒疫情中犧牲的烈士和逝者，街頭隨處可見就地默哀的民眾。但網路也出現不滿「只悼念卻未追責」的留言，諷刺「先前所有的眼淚都被404（網頁被屏蔽）了，而在404這一天卻要人流下眼淚」。"#
			let matches = regex.matches(for: inputString)
			XCTAssertEqual(1, matches.count)
			let text = matches.text(for: matches[0].captures[0])
			XCTAssertEqual(text, #"但網路也出現不滿「只悼念卻未追責」的留言，諷刺「先前所有的眼淚都被404（網頁被屏蔽）了，而在404這一天卻要人流下眼淚」"#)
		}

		try scenario("Matching against an emoji range") {
			let regex = try DSFRegex(#"\|(.+?)\|"#)
			let inputString = #"This is a |😤👩‍👩‍👧‍👦👒🇳🇦|'s test |🧖‍♂️||cat|"#
			let matches = regex.matches(for: inputString)
			XCTAssertEqual(3, matches.count)

			XCTAssertEqual("|😤👩‍👩‍👧‍👦👒🇳🇦|", matches.text(match: 0))
			XCTAssertEqual("|🧖‍♂️|", matches.text(match: 1))
			XCTAssertEqual("|cat|", matches.text(match: 2))

			let text1 = matches.text(match: 0, capture: 0)
			XCTAssertEqual(text1, #"😤👩‍👩‍👧‍👦👒🇳🇦"#)
			let text2 = matches.text(match: 1, capture: 0)
			XCTAssertEqual(text2, #"🧖‍♂️"#)
			let text3 = matches.text(match: 2, capture: 0)
			XCTAssertEqual(text3, #"cat"#)
		}

		try scenario("Simple Unicode German and non-ascii") {
			let regex = try DSFRegex("[0-9]")
			let inputStr = "🇩🇪€4€9"
			XCTAssertTrue(regex.hasMatch(inputStr))
			let matches = regex.matches(for: inputStr)
			XCTAssertEqual(2, matches.count)
			XCTAssertEqual("4", matches.text(match: 0))
			XCTAssertEqual("9", matches.text(match: 1))
		}
	}

	func testEnumerateMatches() throws {
		let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

		var count = 0
		EmailRegex.enumerateMatches(in: inputString) { (match) -> Bool in
			let matchText = inputString[match.range]
			switch count {
			case 0:
				XCTAssertEqual("noodles@compuserve4.nginix.com", matchText)
			case 1:
				XCTAssertEqual("sillytest32@gmail.com", matchText)
			default:
				XCTFail("internal error")
			}

			count += 1
			return true
		}
	}

	func testEnumerateMatchesWithEmojiVerifyingUnicodeOffset() throws {
		let emojiMatches = try DSFRegex(#""(.+?)""#)

		let inputString =
	"""
	 "This is a test." "This is a new emoji 👨🏿‍🦯 good for accessibility"
	 "and another👨🏻‍🦽! How good ﷽ is that?"
	 "caterpillar𐇑🌕🌖🌗🌘🌑moon!"
	 "h̵̰̜̥̺͓̥̤̣̠̪̮͑͛͊̔̏́e̸̢̧̨̻͚̱̳̞͚̺̗͙̲̮̍̓̓̒̂̐͂̓͊̉̄͝͝͠͝l̶̨̧͔̠͍̥̖̯̦̞̈́̀̈́́̆̂̕͝ͅl̶̡̡̨̼̙͔͉̻͔͍̜͚̓̀͑̍̈́̄̒̽͜ó̷̖͕͚̞̰̻͍͚̆" 		"quack"
	"""

		var count = 0
		emojiMatches.enumerateMatches(in: inputString) { match in

			let matchText = inputString[match.range]

			switch count {
			case 0:
				XCTAssertEqual(#""This is a test.""#, matchText)
				XCTAssertEqual("This is a test.", inputString[match.captures[0]])
			case 1:
				XCTAssertEqual(#""This is a new emoji 👨🏿‍🦯 good for accessibility""#, matchText)
				XCTAssertEqual("This is a new emoji 👨🏿‍🦯 good for accessibility", inputString[match.captures[0]])
			case 2:
				XCTAssertEqual(#""and another👨🏻‍🦽! How good ﷽ is that?""#, matchText)
				XCTAssertEqual("and another👨🏻‍🦽! How good ﷽ is that?", inputString[match.captures[0]])
			case 3:
				XCTAssertEqual("caterpillar𐇑🌕🌖🌗🌘🌑moon!", inputString[match.captures[0]])
			case 4:
				XCTAssertEqual("h̵̰̜̥̺͓̥̤̣̠̪̮͑͛͊̔̏́e̸̢̧̨̻͚̱̳̞͚̺̗͙̲̮̍̓̓̒̂̐͂̓͊̉̄͝͝͠͝l̶̨̧͔̠͍̥̖̯̦̞̈́̀̈́́̆̂̕͝ͅl̶̡̡̨̼̙͔͉̻͔͍̜͚̓̀͑̍̈́̄̒̽͜ó̷̖͕͚̞̰̻͍͚̆", inputString[match.captures[0]])
			case 5:
				XCTAssertEqual("quack", inputString[match.captures[0]])

			default:
				XCTFail("internal error")
			}

			count += 1
			return true
		}
	}

	func testEnumerateMatchesStopProcessingDuring() throws {
		let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com, grubby@supernoodle.org lives here"

		try scenario("Store the first two matches") {
			var count = 0
			EmailRegex.enumerateMatches(in: inputString) { (match) -> Bool in
				count += 1
				return count < 2		// skip the last email
			}
			XCTAssertEqual(2, count)
		}

		try scenario("Print the first two matches (README.md example)") {

			var count = 0
			EmailRegex.enumerateMatches(in: inputString) { (match) -> Bool in
				count += 1

				// Extract match information
				let matchRange = match.range
				let nsRange = NSRange(matchRange, in: inputString)
				let matchText = inputString[match.range]
				Swift.print("\(count) - Found '\(matchText)' at range \(nsRange)")

				// Stop processing if we've found more than two
				return count < 2
			}
		}
	}

	func testRegexStringExtensions() throws {
		let regex = try DSFRegex("\\w+")

		try scenario("Check that the string extension works") {
			let results = "This is a test".matches(for: regex)
			XCTAssertEqual(4, results.count)
			XCTAssertEqual(["This", "is", "a", "test"], results.textMatching())
		}

		try scenario("Check that the string extension works") {
			XCTAssertTrue("This is a test".hasMatch(regex))

			let regex2 = try DSFRegex("[a-z]+")
			XCTAssertTrue("cat".hasMatch(regex2))
			XCTAssertTrue("cat".matches(for: regex2).isExactMatch)
			XCTAssertFalse("12345".hasMatch(regex2))
		}
	}

	func testPartialRangeMatches() throws {
		let testString = "Check string PartialRangeTo works with strings"
		//                0000000000111111111122222222223333333333444444
		//                0123456789012345678901234567890123456789012345

		try scenario("Check rangeFrom works") {
			let regex = try DSFRegex("string")

			let testString = "Check string PartialRangeFrom works with strings"

			let results1 = regex.matches(for: testString)
			XCTAssertEqual(2, results1.count)

			let start = testString.index(testString.startIndex, offsetBy: 7)
			let results2 = regex.matches(for: testString, rangeFrom: start...)
			XCTAssertEqual(1, results2.count)

			let start3 = testString.index(testString.startIndex, offsetBy: 6)
			let results3 = regex.matches(for: testString, rangeFrom: start3...)
			XCTAssertEqual(2, results3.count)
		}

		try scenario("Check rangeUpTo works") {
			let regex = try DSFRegex("string")

			let results1 = regex.matches(for: testString)
			XCTAssertEqual(2, results1.count)

			let end2 = testString.index(testString.startIndex, offsetBy: 44)
			let results2 = regex.matches(for: testString, rangeUpTo: ..<end2)
			XCTAssertEqual(1, results2.count)

			let end3 = testString.index(testString.startIndex, offsetBy: 45)
			let results3 = regex.matches(for: testString, rangeUpTo: ..<end3)
			XCTAssertEqual(2, results3.count)
		}

		try scenario("Check rangeUpToIncluding works") {
			let regex = try DSFRegex("string")

			let results = regex.matches(for: testString)
			XCTAssertEqual(2, results.count)

			let end1 = testString.index(testString.startIndex, offsetBy: 43)
			let results1 = regex.matches(for: testString, rangeUpToIncluding: ...end1)
			XCTAssertEqual(1, results1.count)

			let end2 = testString.index(testString.startIndex, offsetBy: 44)
			let results2 = regex.matches(for: testString, rangeUpToIncluding: ...end2)
			XCTAssertEqual(2, results2.count)
		}
	}

	func testCursorSupport() throws {
		let testString = "Check string PartialRangeTo works with strings"
		//                0000000000111111111122222222223333333333444444
		//                0123456789012345678901234567890123456789012345

		let start1 = testString.index(testString.startIndex, offsetBy: 6)
		let end1 = testString.index(testString.startIndex, offsetBy: 12)
		let start2 = testString.index(testString.startIndex, offsetBy: 39)
		let end2 = testString.index(testString.startIndex, offsetBy: 45)

		try scenario("Check incrementer works") {

			let regex = try DSFRegex("string")

			// Get the first match

			var cursor = testString.firstMatch(for: regex)
			XCTAssertNotNil(cursor)
			cursor!.describeRange(in: testString)
			var match = cursor!.range

			XCTAssertEqual(start1, match.lowerBound)
			XCTAssertEqual(end1, match.upperBound)

			// Find the next match

			cursor = testString.nextMatch(for: cursor!)
			XCTAssertNotNil(cursor)
			cursor!.describeRange(in: testString)

			match = cursor!.range

			XCTAssertEqual(start2, match.lowerBound)
			XCTAssertEqual(end2, match.upperBound)

			// Find the next match. This should be nil

			cursor = testString.nextMatch(for: cursor!)
			XCTAssertNil(cursor)
		}
	}

	func testCursorSupportWithLoop() throws {
		let testString = "Check string PartialRangeTo works with strings"
		//                0000000000111111111122222222223333333333444444
		//                0123456789012345678901234567890123456789012345

		let start1 = testString.index(testString.startIndex, offsetBy: 6)
		let end1 = testString.index(testString.startIndex, offsetBy: 12)
		let start2 = testString.index(testString.startIndex, offsetBy: 39)
		let end2 = testString.index(testString.startIndex, offsetBy: 45)

		try scenario("Check incrementer works") {

			let regex = try DSFRegex("string")

			// Get the first match

			var cursor = testString.firstMatch(for: regex)
			XCTAssertNotNil(cursor)
			cursor!.describeRange(in: testString)
			var match = cursor!.range

			XCTAssertEqual(start1, match.lowerBound)
			XCTAssertEqual(end1, match.upperBound)

			// Find the next match

			cursor = testString.nextMatch(for: cursor!, loop: true)
			XCTAssertNotNil(cursor)
			cursor!.describeRange(in: testString)

			match = cursor!.range

			XCTAssertEqual(start2, match.lowerBound)
			XCTAssertEqual(end2, match.upperBound)

			// Find the next match. This should loop through to the
			// start of the string as we've run over the end of the string

			cursor = testString.nextMatch(for: cursor!, loop: true)

			XCTAssertNotNil(cursor)
			cursor!.describeRange(in: testString)
			XCTAssertEqual(start1, cursor!.range.lowerBound)
			XCTAssertEqual(end1, cursor!.range.upperBound)

			cursor = testString.nextMatch(for: cursor!, loop: true)

			XCTAssertNotNil(cursor)
			cursor!.describeRange(in: testString)
			XCTAssertEqual(start2, cursor!.range.lowerBound)
			XCTAssertEqual(end2, cursor!.range.upperBound)
		}
	}

	func testIncrementerStartSomewhereElseInString() throws {
		let testString = "Check string PartialRangeTo works with strings"
		//                0000000000111111111122222222223333333333444444
		//                0123456789012345678901234567890123456789012345

		//let start1 = testString.index(testString.startIndex, offsetBy: 6)
		let end1 = testString.index(testString.startIndex, offsetBy: 12)
		let start2 = testString.index(testString.startIndex, offsetBy: 39)
		let end2 = testString.index(testString.startIndex, offsetBy: 45)

		try scenario("Check incrementer works") {

			let regex = try DSFRegex("string")

			// Get the first match

			var cursor = testString.firstMatch(for: regex, startingAt: end1)
			XCTAssertNotNil(cursor)
			cursor!.describeRange(in: testString)
			XCTAssertEqual(start2, cursor!.range.lowerBound)
			XCTAssertEqual(end2, cursor!.range.upperBound)

			// Find the next match. This should be nil

			cursor = testString.nextMatch(for: cursor!)
			XCTAssertNil(cursor)
		}
	}

	func index(_ str: String, offset: Int) -> String.Index {
		return str.index(str.startIndex, offsetBy: offset)
	}


	func testIncrementerDoWhile() throws {
		let testString = "Check string PartialRangeTo works with strings string"
		//                00000000001111111111222222222233333333334444444444555
		//                01234567890123456789012345678901234567890123456789012

		//let start1 = testString.index(testString.startIndex, offsetBy: 6)
		let results = [
			index(testString, offset: 6) ..< index(testString, offset: 12),
			index(testString, offset: 39) ..< index(testString, offset: 45),
			index(testString, offset: 47) ..< index(testString, offset: 53)
		]

		try scenario("Check incrementer works") {

			let regex = try DSFRegex("string")

			var visitor = testString.firstMatch(for: regex)

			var i = 0
			while visitor != nil {
				let v = visitor!
				v.describeRange(in: testString)
				XCTAssertEqual(results[i], v.range)
				visitor = testString.nextMatch(for: v)
				i += 1
			}

			XCTAssertEqual(3, i)
		}
	}
}
