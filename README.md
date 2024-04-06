# DSFRegex

A Swift regex class abstracting away some of the complexities of `NSRegularExpression`

![tag](https://img.shields.io/github/v/tag/dagronf/DSFRegex)
![swift versions](https://img.shields.io/badge/Swift-5.3+-orange.svg)
![Platform support](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20tvos%20%7C%20watchos%20%7C%20macCatalyst%20%7C%20linux-lightgrey.svg?style=flat-square)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/dagronf/DSFRegex/blob/master/LICENSE) 
![Build](https://img.shields.io/github/actions/workflow/status/dagronf/DSFRegex/swift.yml)

## Why?

Every time I have to use `NSRegularExpression` in Swift I make the same mistakes over and over regarding ranges and range conversions between `NSRange` and `Range<String.Index>`.

Also, pulling content out using capture groups is tedious and a little error-prone. I wanted to abstract away from of the things that I kept stuffing up.

## TL;DR - Show me something!

```swift
let inputText: String = <some text to match against>

// Build the regex to match against (in this case, <number>\t<string>)
// This regex has two capture groups, one for the number and one for the string.
let regex = try DSFRegex(#"(\d*)\t\"([^\"]+)\""#)

// Retrieve ALL the matches for the supplied text
let searchResult = regex.matches(for: inputText)

// Loop over each of the matches found, and print them out
searchResult.forEach { match in 
   let foundStr = inputText[match.range]          // The text of the entire match
   let numberVal = inputText[match.captures[0]]   // Retrieve the first capture group text.
   let stringVal = inputText[match.captures[1]]   // Retrieve the second capture group text.

   Swift.print("Number is \(numberVal), String is \(stringVal)")
}
```

The basic structure of a 'matches' result is as follows

```
Matches
  > matches: An array of regex matches
    > range: A match range. This range specifies the match range within the original text being searched
    > captures: An array of capture groups
       > A capture range. This range represents the range of a capture within the original text being searched
```

## Usage

All ranges provided back to the caller (and conversely, when passing ranges to the regex object) are in the range of the Swift `String` passed in for the match. 

This is important, as `NSRegularExpression` uses `NSString` and the code points and character range information are different between `NSString` and `String`, especially when dealing with characters in the high Unicode ranges such as emoji 🇦🇲 👨‍👩‍👦.

### Creation

You create a regex matching object using the constructor and a regex pattern. If the regex is badly formatted or cannot be compiled, this constructor will throw.

```swift
// Match against dummy phone numbers XXXX-YYY-ZZZ
let phoneNumberRegex = try DSFRegex(#"(\d{4})-(\d{3})-(\d{3})"#)
```

### Matching 

To check whether a string matches against the regex, use the `hasMatch` method.

```swift
let hasAMatch = phoneNumberRegex.hasMatch("0499-999-999")   // true
let noMatch = phoneNumberRegex.hasMatch("0499 999 999")     // false
```

If you want to extract all the match information, use the `matches` method.

```swift
let result = phoneNumberRegex.matches(for: "0499-999-999 0491-111-444 4324-222-123")
result.forEach { match in 
   let matchText = result.text(for: match.element)
   Swift.print("Match `\(matchText)`")
   for capture in match.captures {
      let captureText = result.text(for: capture)
      Swift.print(" - `\(captureText)`")
   }
}
```

### Enumeration

If you have a large input text or a complex regex that will take a while to process or you have constrained memory conditions you can choose to enumerate the match results rather than process everything up front.

The enumeration method allows you to stop processing at any time or any point in the process (eg. if you have limited time constraints, or are looking for a specific match within a text).

```swift
/// Find all email addresses within a text
let inputString = "… some input string …"
let emailRegex = try DSFRegex("… some regex …")
emailRegex.enumerateMatches(in: inputString) { (match) -> Bool in

   // Extract match information
   let matchRange = match.range
   let matchText = inputString[match.range]
   Swift.print("Found '\(matchText)' at range \(matchRange)")
   
   // Continue processing
   return true
}
```

### String search cursor

A string search cursor is useful when you are searching sporadically within a string, say in response to a user clicking on the 'next' button.  The cursor keeps track of the current match, and is used when locating the next match in the string.

```swift
var searchCursor: DSFRegex.Cursor?
var content: String

@IBAction func startSearch(_ sender: Any) {
   let regex = DSFRegex(... some pattern ...)
   
   // Find the first match in the string
   self.searchCursor = self.content.firstMatch(for: regex)
   
   self.displayForCurrentSearch()
}

@IBAction func nextSearchResult(_ sender: Any) {
   if let previous = self.searchCursor {
   	   // Find the next match in the string from the 
      self.searchCursor = self.content.nextMatch(for: previous)
   }
   self.displayForCurrentSearch()
}

internal func displayForCurrentSearch() {
   // Update the UI reflecting the search result found in self.searchCursor
   ...
}
```

### Matching string replacement

Returns a new string containing matching regular expressions replaced with a template string.

```swift
// Redact email addresses within the text
let emailRegex = try DSFRegex("… some regex …")
let redacted = emailRegex.stringByReplacingMatches(
    in: inputString,
    withTemplate: NSRegularExpression.escapedTemplate(for: "<REDACTED-EMAIL-ADDRESS>")
)
```

## Classes

### DSFRegex

The primary class used to perform a regex match.

#### DSFRegex.Matches

An object that contains all of the results of the regex matched against a text. It also provides a number of methods to help extract text from a match and/or capture object.

#### DSFRegex.Match

A single match object. Stores the range of the match within the original string.  If capture groups were defined within the regex also contains an array of the capture group objects.

#### DSFRegex.Capture

A capture represents a single range matching a capture within a regex result.  Each `match` may contain 0 or more captures depending on the captures available in the regex

#### DSFRegex.Cursor

An incremental cursor object used when searching via the `String` extension.

## Integration

### Cocoapods

`pod 'DSFRegex', :git => 'https://github.com/dagronf/DSFRegex/'`

### Swift package manager

Add `https://github.com/dagronf/DSFRegex` to your project.

### Direct

Copy the files in the `Sources/DSFRegex` into your project

## Examples

For more examples and usage, you can find a series of tests in the `Tests` folder.

### Phone number matching

```swift
let phoneNumberRegex = try DSFRegex(#"(\d{4})-(\d{3})-(\d{3})"#)
let results = phoneNumberRegex.matches(for: "4499-999-999 3491-111-444 4324-222-123")

// results.numberOfMatches == 3
// results.text(match: 0) == "4499-999-999"
// results.text(match: 1) == "3491-111-444"
// results.text(match: 2) == "4324-222-123"

// Just retrieve the text for each of the matches
let textMatches = results.textMatching()  // == ["4499-999-999", "3491-111-444, "4324-222-123"]

```

If you're only interested in the first match, use

```swift
let first = phoneNumberRegex.firstMatch(in: "4499-999-999 3491-111-444 4324-222-123")
```

### Data extraction

```swift
let allMatches = phoneNumberRegex.matches(for: "0499-999-999 0491-111-444 4324-222-123")
for match in allMatches.matches.enumerated() {
   let matchText = allMatches.text(for: match.element)
   Swift.print("Match (\(match.offset)) -> `\(matchText)`")
   for capture in match.element.capture.enumerated() {
      let captureText = allMatches.text(for: capture.element)
      Swift.print("  Capture (\(capture.offset)) -> `\(captureText)`")
   }
}
```

The output :-

```
Match (0) -> `0499-999-888`
  Capture (0) -> `0499`
  Capture (1) -> `999`
  Capture (2) -> `888`
Match (1) -> `0491-111-444`
  Capture (0) -> `0491`
  Capture (1) -> `111`
  Capture (2) -> `444`
Match (2) -> `4324-222-123`
  Capture (0) -> `4324`
  Capture (1) -> `222`
  Capture (2) -> `123`
```

### Print just the first two email addresses in a text

```swift
/// Find all email addresses within a text
let emailRegex = try DSFRegex("… some regex …")
let inputString = "This is a test.\n noodles@compuserve4.nginix.com and sillytest32@gmail.com, grubby@supernoodle.org lives here"

var count = 0
emailRegex.enumerateMatches(in: inputString) { (match) -> Bool in
   
   count += 1

   // Extract match information
   let matchRange = match.range
   let nsRange = NSRange(matchRange, in: inputString)
   let matchText = inputString[match.range]
   Swift.print("\(count) - Found '\(matchText)' at range \(nsRange)")

   // Stop processing if we've found more than two
   return count < 2
}
```

Output :-

```
1 - Found 'noodles@compuserve4.nginix.com' at range {17, 30}
2 - Found 'sillytest32@gmail.com' at range {52, 21}
```

# License

```
MIT License

Copyright (c) 2024 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
