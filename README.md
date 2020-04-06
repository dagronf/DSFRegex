# DSFRegex

A Swift regex class abstracting away some of the complexities of NSRegularExpression

<p align="center">
    <img src="https://img.shields.io/github/v/tag/dagronf/DSFRegex" />
    <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" />
    <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
    <img src="https://img.shields.io/badge/pod-compatible-informational" alt="CocoaPods" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>

## Why

Every time I have to use `NSRegularExpression` in Swift I make the same mistakes over and over regarding ranges and range conversions between `NSRange` and `Range<String.Index>`.

Also, pulling content out using capture groups is tedious and a little error-prone. I wanted to abstract away from of the things that I kept stuffing up.

## Usage

You create a regex matching object using the constructor. If the regex is badly formatted or cannot be compiled, this constructor will throw.

```swift
// Match against dummy phone numbers XXXX-YYY-ZZZ
let phoneNumberRegex = try DSFRegex(#"(\d{4})-(\d{3})-(\d{3})"#)
```

To just check whether a string matches against the regex, use the `matches` method

```swift
let hasAMatch = phoneNumberRegex.matches(in: "0499-999-999")   // true
let noMatch = phoneNumberRegex.matches(in: "0499 999 999")   // false
```

If you want to extract the data from the matches, use the `allMatches` method.

```swift
let matches = phoneNumberRegex.allMatches(in: "0499-999-999 0491-111-444 4324-222-123")
//assert(matches.numberOfMatches == 3)

for match in matches.enumerated() {
   let matchText = allMatches.text(for: match.element)
   Swift.print("Match (\(match.offset)) -> `\(matchText)`")
   for capture in match.element.capture.enumerated() {
      let captureText = allMatches.text(for: capture.element)
      Swift.print("  Capture (\(capture.offset)) -> `\(captureText)`")
   }
}
```
The output from this looks like :-

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

You use the `DSFRegex.Matches` object to retrieve text for each of match component.

### Simple example

```swift
let phoneNumberRegex = try DSFRegex(#"(\d{4})-(\d{3})-(\d{3})"#)
let results = phoneNumberRegex.allMatches(in: "4499-999-999 3491-111-444 4324-222-123")

// Just retrieve the text for each of the matches
let textMatches = results.textMatching()  // == ["4499-999-999", "3491-111-444, "4324-222-123"]

// results.numberOfMatches == 3
// results.text(match: 0) == "4499-999-999"
// results.text(match: 1) == "3491-111-444"
// results.text(match: 2) == "4324-222-123"
```

If you're only interested in the first match, use

```swift
let first = phoneNumberRegex.firstMatch(in: "4499-999-999 3491-111-444 4324-222-123")
```

## String replacement

Returns a new string containing matching regular expressions replaced with a template string.

```swift
// Redact email addresses within the text
let redacted = EmailRegex.stringByReplacingMatches(
    in: inputString,
    withTemplate: NSRegularExpression.escapedTemplate(for: "<REDACTED-EMAIL-ADDRESS>")
)
```

## Classes

### DSFRegex

The core class used to perform a regex search and match.

### DSFRegex.Matches

An object that contains all of the results of the regex matched against a text. It also provides a number of methods to help extract text from a match and/or capture object.

### DSFRegex.Match

A single match object. Stores the range of the match within the original string.  If capture groups were defined within the regex also contains an array of the capture group objects.

### DSFRegex.Capture

A capture represents a single range matching a capture within a regex result.  Each `match` may contain 0 or more captures depending on the captures available in the regex

## Integration

### Cocoapods

`pod 'DSFRegex', :git => 'https://github.com/dagronf/DSFRegex/'`

### Swift package manager



# License

```
MIT License

Copyright (c) 2020 Darren Ford

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
