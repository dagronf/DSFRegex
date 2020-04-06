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

@testable import DSFRegex
import XCTest

final class DSFRegexTests: XCTestCase {

	func testThrowConstructor() {

		// Invalid regular expression: /(?<={index:)\d+(?=})/: Invalid group
		XCTAssertThrowsError(try DSFRegex(#"(?<={index:)\d+(?=})"#))
	}

	func testPhoneMatches() {
		performTest {
			let phoneNumberRegex = try DSFRegex(#"(\d{4})-(\d{3})-(\d{3})"#)

			XCTAssertTrue(phoneNumberRegex.matches(in: "3499-999-999"))
			XCTAssertFalse(phoneNumberRegex.matches(in: "3499 999-999"))

			let allMatches = phoneNumberRegex.allMatches(in: "4499-999-888 4491-111-444 4324-222-123")
			XCTAssertEqual(3, allMatches.numberOfMatches)

			XCTAssertEqual("4499-999-888", allMatches.text(for: allMatches[0]))
			XCTAssertEqual("4491-111-444", allMatches.text(for: allMatches[1]))
			XCTAssertEqual("4324-222-123", allMatches.text(for: allMatches[2]))

			XCTAssertEqual(["4499", "999", "888"], allMatches.text(forCapturesIn: allMatches[0]))
			XCTAssertEqual(["4491", "111", "444"], allMatches.text(forCapturesIn: allMatches[1]))
			XCTAssertEqual(["4324", "222", "123"], allMatches.text(forCapturesIn: allMatches[2]))

			let textMatches = allMatches.textMatching()
			XCTAssertEqual(["4499-999-888", "4491-111-444", "4324-222-123"], textMatches)

			for match in allMatches.enumerated() {
				let matchText = allMatches.text(for: match.element)
				Swift.print("Match (\(match.offset)) -> `\(matchText)`")
				for capture in match.element.capture.enumerated() {
					let captureText = allMatches.text(for: capture.element)
					Swift.print("  Capture (\(capture.offset)) -> `\(captureText)`")
				}
			}

			let regex = try DSFRegex(#"([\+-]?)(\d+)(?:\.(\d+))?"#)
			let matches = regex.allMatches(in: "11.15 -9.942")
			XCTAssertEqual(matches.numberOfMatches, 2)

			// Get the text for the matches
			let matchText1 = matches.text(for: matches.match[0])
			XCTAssertEqual("11.15", matchText1)
			let matchText2 = matches.text(for: matches.match[1])
			XCTAssertEqual("-9.942", matchText2)

			// Get the contents of the capture groups for these matches
			let captureTexts1 = matches.text(forCapturesIn: matches.match[0])
			XCTAssertEqual(["", "11", "15"], captureTexts1)
			let captureTexts2 = matches.text(forCapturesIn: matches.match[1])
			XCTAssertEqual(["-", "9", "942"], captureTexts2)
		}
	}

	func testNonCapture() {
		performTest {
			let r = try DSFRegex("(\\+|-)?([[:digit:]]+)")
			var results = r.allMatches(in: "bitter lemon")
			XCTAssertEqual(0, results.numberOfMatches)
			XCTAssertTrue(results.isEmpty)
			results = r.allMatches(in: "1234")
			XCTAssertEqual(1, results.numberOfMatches)
			XCTAssertFalse(results.isEmpty)

			// Note here that the capture group (\\+|-)? is optional -- the library
			// will add in a capture with an empty range to keep the capture group -> array position matching
			XCTAssertEqual(2, results[0].capture.count)
			XCTAssertTrue(results[0].capture[0].isEmpty)
			XCTAssertFalse(results[0].capture[1].isEmpty)

			results = r.allMatches(in: "-9870")
			XCTAssertEqual(1, results.numberOfMatches)

			// Note that the regex does not handle a fraction value - hence the . breaks the number into two
			results = r.allMatches(in: "-987.0")
			XCTAssertEqual(2, results.numberOfMatches)
			XCTAssertEqual("-", results.text(for: results.match[0].capture[0]))
			XCTAssertEqual("987", results.text(for: results.match[0].capture[1]))

			XCTAssertEqual("", results.text(for: results.match[1].capture[0]))
			XCTAssertEqual("0", results.text(for: results.match[1].capture[1]))
		}
	}

	func testSimpleOne() {
		performTest {
			let r = try DSFRegex("(.*) [sS](\\d\\d)[eE](\\d\\d) - (.*)", options: .caseInsensitive)
			let results = r.allMatches(in: "ChoccyWokky s03e01 - Noodles.mp4")
			XCTAssertEqual(1, results.numberOfMatches)
			XCTAssertEqual(4, results[0].capture.count)
			XCTAssertEqual("ChoccyWokky", results.text(for: results[0].capture[0]))
			print(results)
		}
	}

	func testSimpleTwo() {
		performTest {
			let r = try DSFRegex("(.*) [sS](\\d\\d)[eE](\\d\\d) - (.*)", options: .caseInsensitive)
			let results = r.allMatches(in: "ChoccyWokky s03e01 - Noodles.pdf\nChoccyWokky s03e02 - Caterpillar.pdf")
			XCTAssertEqual(2, results.numberOfMatches)

			XCTAssertFalse(results.isExactMatch)

			XCTAssertEqual(4, results[0].capture.count)
			let captures0 = results.text(forCapturesIn: results[0])
			XCTAssertEqual(["ChoccyWokky", "03", "01", "Noodles.pdf"], captures0)

			XCTAssertEqual(4, results[1].capture.count)
			let captures1 = results.text(for: results[1].capture)
			XCTAssertEqual(["ChoccyWokky", "03", "02", "Caterpillar.pdf"], captures1)

			// Just to check that this isn't being fudged
			XCTAssertNotEqual(["ChoccyWo2kky", "03", "02", "Caterpillar.pdf"], captures1)
		}
	}

	func testFractional() {
		performTest {
			let r = try DSFRegex(#"([\+-]?)(\d+)(?:\.(\d+))?"#)

			// Simple fractional
			var results = r.allMatches(in: "11.15")

			XCTAssertEqual(1, results.numberOfMatches)
			XCTAssertEqual(3, results[0].capture.count)
			XCTAssertTrue(results[0].capture[0].isEmpty)
			XCTAssertEqual("", results.text(for: results[0].capture[0]))
			XCTAssertEqual("11", results.text(for: results[0].capture[1]))
			XCTAssertEqual("15", results.text(for: results[0].capture[2]))

			results = r.allMatches(in: "  11.15")
			XCTAssertEqual(1, results.numberOfMatches)
			XCTAssertTrue(results[0].capture[0].isEmpty)
			XCTAssertEqual("", results.text(for: results[0].capture[0]))
			XCTAssertEqual("11", results.text(for: results[0].capture[1]))
			XCTAssertEqual("15", results.text(for: results[0].capture[2]))

			results = r.allMatches(in: "  11.15 -22.4 +-2.4")
			XCTAssertEqual(3, results.numberOfMatches)

			results = r.allMatches(in: "-12345657.890")
			XCTAssertEqual(1, results.numberOfMatches)
			XCTAssertEqual("-", results.text(for: results[0].capture[0]))
			XCTAssertFalse(results[0].capture[0].isEmpty)
			XCTAssertEqual("12345657", results.text(for: results[0].capture[1]))
			XCTAssertEqual("890", results.text(for: results[0].capture[2]))

			XCTAssertEqual(#"([\+-]?)(\d+)(?:\.(\d+))?"#, r.pattern)
		}
	}

	func testBrokenTwo() {
		performTest {
			let r = try DSFRegex("(.*) [sS](\\d\\d)[eE](\\d\\d) - (.*)", options: .caseInsensitive)
			let results = r.allMatches(in: "ChoccyWokky s03e01 - Noodles.mp4\nChoccyWokky s03d02 - Caterpillar.mp4")
			XCTAssertEqual(1, results.numberOfMatches)
			XCTAssertEqual(4, results[0].capture.count)
			print(results)
		}
	}

	func testSequence() {
		performTest {
			let r = try DSFRegex("([\\+-]?)(\\d+)(?:\\.(\\d+))?")
			let results = r.allMatches(in: "  11.15 -22.4 +-2.4")
			XCTAssertEqual(3, results.numberOfMatches)
			for match in results.enumerated() {
				// ALL matches should have the same number of captures in their capture group,
				// even if some of them are empty
				XCTAssertEqual(3, match.element.capture.count)
				if match.offset == 0 {
					XCTAssertTrue(match.element.capture[match.offset].isEmpty)
				} else {
					XCTAssertFalse(match.element.capture[match.offset].isEmpty)
				}
			}
		}
	}

	lazy var EmailRegex: DSFRegex = {
		let emailAddressRegex = #"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])"#
		guard let r = try? DSFRegex(emailAddressRegex, options: .caseInsensitive) else {
			fatalError("Unable to create email regex")
		}
		return r
	}()

	func testEmailValidation() {
		// Email regex from here -- https://emailregex.com

		performTest {
			let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

			// Test that there are matches.
			XCTAssertTrue(EmailRegex.matches(in: inputString))

			let matches = EmailRegex.allMatches(in: inputString)
			XCTAssertEqual(2, matches.numberOfMatches)

			let email1 = matches.text(for: matches[0])
			XCTAssertEqual("noodles@compuserve4.nginix.com", email1)
			XCTAssertEqual(0, matches[0].capture.count)

			let email2 = matches.text(for: matches[1])
			XCTAssertEqual("sillytest32@gmail.com", email2)
			XCTAssertEqual(0, matches[1].capture.count)

			// Just return the email addresses
			let textMatches = matches.textMatching()
			XCTAssertEqual(["noodles@compuserve4.nginix.com", "sillytest32@gmail.com"], textMatches)
		}
	}

	func testFirstMatch() {
		performTest {
			let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

			// Test that there are matches.
			XCTAssertTrue(EmailRegex.matches(in: inputString))

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
				XCTAssertEqual("a3c113", hexStrings[first!.capture[0]])

				/// First match in a range which isn't the start
				let second = regex.firstMatch(in: hexStrings, range: hexStrings.range(5...))
				XCTAssertNotNil(second)
				XCTAssertEqual("bad", hexStrings[second!.capture[0]])

				let results = regex.allMatches(in: hexStrings)
				XCTAssertEqual(2, results.numberOfMatches)		// #noodle isn't a valid hex string
				XCTAssertEqual("a3c113", results.text(match: 0, capture: 0))
				XCTAssertEqual("bad", results.text(match: 1, capture: 0))
			}
		}
	}

	func testStringReplacement() {
		performTest {
			let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

			try scenario("Verify that our regex matches two email addresses") {
				let matches = EmailRegex.allMatches(in: inputString)
				XCTAssertEqual(2, matches.numberOfMatches)

				XCTAssertEqual("noodles@compuserve4.nginix.com", matches.text(for: matches[0]))
				XCTAssertEqual("sillytest32@gmail.com", matches.text(for: matches[1]))
			}

			try scenario("Replace all the email addresses in a string with a replacement value") {
				let REDAC = "This is a test.\n <REDACTED-EMAIL-ADDRESS> and <REDACTED-EMAIL-ADDRESS> lives here"
				let redacted = EmailRegex.stringByReplacingMatches(
					in: inputString,
					withTemplate: NSRegularExpression.escapedTemplate(for: "<REDACTED-EMAIL-ADDRESS>")
				)
				XCTAssertEqual(REDAC, redacted)
			}

			try scenario("Replace only the first one (index 52 is just after the 'and')") {
				let REDAC2 = "This is a test.\n <REDACTED-EMAIL-ADDRESS> and sillytest32@gmail.com lives here"
				let redacted2 = EmailRegex.stringByReplacingMatches(
					in: inputString, withTemplate: "<REDACTED-EMAIL-ADDRESS>",
					range: inputString.range(0 ..< 52),
					options: []
				)
				XCTAssertEqual(REDAC2, redacted2)
			}

			try scenario("Replace only the second one (search only after the 30th character") {
				let REDAC2 = "This is a test.\n noodles@compuserve4.nginix.com and <REDACTED-EMAIL-ADDRESS> lives here"
				let redacted2 = EmailRegex.stringByReplacingMatches(
					in: inputString, withTemplate: "<REDACTED-EMAIL-ADDRESS>",
					range: inputString.range(30...),
					options: []
				)
				XCTAssertEqual(REDAC2, redacted2)
			}
		}
	}

	func testExactMatch() {
		performTest {
			var matches = EmailRegex.allMatches(in: "noodles@compuserve4.nginix.com")
			XCTAssertEqual(1, matches.numberOfMatches)
			XCTAssertTrue(matches.isExactMatch)

			matches = EmailRegex.allMatches(in: "email - noodles@compuserve4.nginix.com")
			XCTAssertEqual(1, matches.numberOfMatches)
			XCTAssertFalse(matches.isExactMatch)

			matches = EmailRegex.allMatches(in: "noodles@compuserve4.nginix.com ")
			XCTAssertEqual(1, matches.numberOfMatches)
			XCTAssertFalse(matches.isExactMatch)
		}
	}

	func testSearchInRange() {
		performTest {
			let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

			let matches = EmailRegex.allMatches(in: inputString)
			XCTAssertEqual(2, matches.numberOfMatches)

			XCTAssertTrue(EmailRegex.matches(in: inputString))

			let noMatchRange = inputString.range(0 ..< 30)
			XCTAssertFalse(EmailRegex.matches(in: inputString, range: noMatchRange))

			let range2Matches = EmailRegex.allMatches(in: inputString, range: noMatchRange)
			XCTAssertEqual(0, range2Matches.numberOfMatches)

			let firstCheckRange = inputString.range(0 ..< 52)
			let range1Matches = EmailRegex.allMatches(in: inputString, range: firstCheckRange)
			XCTAssertEqual(1, range1Matches.numberOfMatches)
		}
	}

	func testUnicodeTests() {
		performTest {
			try scenario("Test that non-ascii character set can be matched") {
				let regex = try DSFRegex(#"^(?:[\p{L}\p{Mn}\p{Pd}\'\x{2019}]+\s[\p{L}\p{Mn}\p{Pd}\'\x{2019}]+\s?)+$"#)
				let matches = regex.allMatches(in: "John Elkjærd")
				XCTAssertEqual(1, matches.numberOfMatches)
				XCTAssertFalse(regex.matches(in: "H4nn3 Andersen"))
			}

			try scenario("A sub-range of chinese text can be matched correctly") {
				let regex = try DSFRegex(#"。(.*?)。"#)
				let inputString = #"中國4日舉行全國哀悼活動，追悼在新型冠病毒疫情中犧牲的烈士和逝者，街頭隨處可見就地默哀的民眾。但網路也出現不滿「只悼念卻未追責」的留言，諷刺「先前所有的眼淚都被404（網頁被屏蔽）了，而在404這一天卻要人流下眼淚」。"#
				let matches = regex.allMatches(in: inputString)
				XCTAssertEqual(1, matches.numberOfMatches)
				let text = matches.text(for: matches[0].capture[0])
				XCTAssertEqual(text, #"但網路也出現不滿「只悼念卻未追責」的留言，諷刺「先前所有的眼淚都被404（網頁被屏蔽）了，而在404這一天卻要人流下眼淚」"#)
			}

			try scenario("Matching against an emoji range") {
				let regex = try DSFRegex(#"\|(.+?)\|"#)
				let inputString = #"This is a |😤👩‍👩‍👧‍👦👒🇳🇦|'s test |🧖‍♂️||cat|"#
				let matches = regex.allMatches(in: inputString)
				XCTAssertEqual(3, matches.numberOfMatches)

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
				XCTAssert(regex.matches(in: inputStr))
				let matches = regex.allMatches(in: inputStr)
				XCTAssertEqual(2, matches.numberOfMatches)
				XCTAssertEqual("4", matches.text(match: 0))
				XCTAssertEqual("9", matches.text(match: 1))
			}
		}
	}

	func testEnumerateMatches() {
		performTest {
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
	}

	func testEnumerateMatchesStopProcessingDuring() {
		performTest {
			let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com, grubby@supernoodle.org lives here"

			var count = 0
			EmailRegex.enumerateMatches(in: inputString) { (match) -> Bool in
				count += 1
				return count < 2		// skip the last email
			}
			XCTAssertEqual(2, count)
		}
	}

	static var allTests = [
		("testThrowConstructor", testThrowConstructor),
		("testPhoneMatches", testPhoneMatches),
		("testNonCapture", testNonCapture),
		("testSimpleOne", testSimpleOne),
		("testSimpleTwo", testSimpleTwo),
		("testFractional", testFractional),
		("testSequence", testSequence),
		("testEmailValidation", testEmailValidation),
		("testStringReplacement", testStringReplacement),
		("testExactMatch", testExactMatch),
		("testSearchInRange", testSearchInRange),
		("testUnicodeTests", testUnicodeTests),
		("testEnumerateMatchesStopProcessingDuring", testEnumerateMatchesStopProcessingDuring)
	]
}
