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

import XCTest
@testable import DSFRegex

private func performTest(closure: () throws -> Void) {
	do {
		try closure()
	} catch {
		XCTFail("Unexpected error thrown: \(error)")
	}
}

final class DSFRegexTests: XCTestCase {

	func testDocs() {
		performTest {

			let phoneNumberRegex = try DSFRegex(#"(\d{4})-(\d{3})-(\d{3})"#)
			XCTAssertTrue(phoneNumberRegex.matches(in: "0499-999-999"))
			XCTAssertFalse(phoneNumberRegex.matches(in: "0499 999-999"))

			let allMatches = phoneNumberRegex.allMatches(in: "0499-999-888 0491-111-444 4324-222-123")
			XCTAssertEqual(3, allMatches.numberOfMatches)

			XCTAssertEqual("0499-999-888", allMatches.text(for: allMatches[0]))
			XCTAssertEqual("0491-111-444", allMatches.text(for: allMatches[1]))
			XCTAssertEqual("4324-222-123", allMatches.text(for: allMatches[2]))

			XCTAssertEqual(["0499", "999", "888"], allMatches.text(forCapturesIn: allMatches[0]))
			XCTAssertEqual(["0491", "111", "444"], allMatches.text(forCapturesIn: allMatches[1]))
			XCTAssertEqual(["4324", "222", "123"], allMatches.text(forCapturesIn: allMatches[2]))

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
				}
				else {
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
		}
	}

	func testReplacement() {
		performTest {
			let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com lives here"

			let matches = EmailRegex.allMatches(in: inputString)
			XCTAssertEqual(2, matches.numberOfMatches)

			// Replace all the email addresses
			let REDAC = "This is a test.\n <REDACTED-EMAIL-ADDRESS> and <REDACTED-EMAIL-ADDRESS> lives here"
			let redacted = EmailRegex.stringByReplacingMatches(in: inputString, withTemplate: NSRegularExpression.escapedTemplate(for: "<REDACTED-EMAIL-ADDRESS>"))
			XCTAssertEqual(REDAC, redacted)

			/// Replace only the first one (index 52 is just after the 'and')
			let REDAC2 = "This is a test.\n <REDACTED-EMAIL-ADDRESS> and sillytest32@gmail.com lives here"
			let redacted2 = EmailRegex.stringByReplacingMatches(
				in: inputString, withTemplate: "<REDACTED-EMAIL-ADDRESS>",
				range: inputString.startIndex ..< inputString.index(inputString.startIndex, offsetBy: 52),
				options: [])
			XCTAssertEqual(REDAC2, redacted2)
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

	static var allTests = [
		("testDocs", testDocs),
		("testNonCapture", testNonCapture),
		("testSimpleOne", testSimpleOne),
		("testSimpleTwo", testSimpleTwo),
		("testFractional", testFractional),
		("testSequence", testSequence),
		("testEmailValidation", testEmailValidation),
		("testReplacement", testReplacement),
		("testExactMatch", testExactMatch),
	]
}
