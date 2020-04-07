//
//  DSFAttributedStringStream.swift
//  DSFAttributedStringStream
//
//  Created by Darren Ford on 25/3/19.
//  Copyright © 2019 Darren Ford. All rights reserved.
//
//  MIT License
//
//  Copyright (c) 2019 Darren Ford
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


#if os(iOS) || os(tvOS)
import UIKit
public typealias FontSpecifier = UIFont
public typealias ColorSpecifier = UIColor
#else
import AppKit
public typealias FontSpecifier = NSFont
public typealias ColorSpecifier = NSColor
#endif

extension NSAttributedString {
	static func stream(creationBlock: (DSFAttributedStringStream) -> Void) -> NSAttributedString {
		let stream = DSFAttributedStringStream()
		creationBlock(stream)
		return stream.attributed
	}
}

infix operator <==: MultiplicationPrecedence

@discardableResult
public func <==(left: DSFAttributedStringStream, right: String) -> DSFAttributedStringStream {
	left.append(right)
	return left
}

@discardableResult
public func <==(left: DSFAttributedStringStream, right: [NSAttributedString.Key: Any]) -> DSFAttributedStringStream {
	return left.set(right)
}

@objc public class DSFAttributedStringStream: NSObject {

	fileprivate var attrs: [(key: NSAttributedString.Key, value: Any, startPos: Int, length: Int)] = []
	fileprivate var text = NSMutableAttributedString()

	fileprivate func add(key: NSAttributedString.Key, value: Any) {
		self.attrs.append((key, value, self.text.length, -1))
	}

	fileprivate func add(_ attributes: [NSAttributedString.Key: Any]) -> DSFAttributedStringStream {
		for item in attributes {
			self.add(key: item.key, value: item.value)
		}
		return self
	}

	@discardableResult
	fileprivate func remove(key: NSAttributedString.Key) -> DSFAttributedStringStream {
		for i in 0 ..< attrs.count {
			if attrs[i].length == -1 && attrs[i].key == key {
				attrs[i].length = self.text.length - attrs[i].startPos
			}
		}
		return self
	}

	@discardableResult
	fileprivate func removeAll() -> DSFAttributedStringStream {
		for i in 0 ..< attrs.count {
			if attrs[i].length == -1 {
				attrs[i].length = self.text.length - attrs[i].startPos
			}
		}
		return self
	}

	@objc public var attributed: NSAttributedString {
		let result = self.text.mutableCopy() as! NSMutableAttributedString
		for item in self.attrs {
			let len = (item.length != -1) ? item.length : self.text.length - item.startPos
			result.addAttribute(item.key, value: item.value, range: NSRange(location: item.startPos, length: len))
		}
		return result
	}
}

extension NSParagraphStyle {
	static func stream(_ configureBlock: (NSMutableParagraphStyle) -> Void) -> NSParagraphStyle {
		let obj = NSMutableParagraphStyle()
		configureBlock(obj)
		return obj
	}
}

extension NSShadow {
	static func stream(_ configureBlock: (NSShadow) -> Void) -> NSShadow {
		let obj = NSShadow()
		configureBlock(obj)
		return obj
	}
}

// MARK: Appending text and images

public extension DSFAttributedStringStream {

	/// Append a string to the stream.  The text is styled using the currently active styles
	@discardableResult
	@objc func append(_ rhs: String) -> DSFAttributedStringStream {
		self.text.append(NSAttributedString(string: rhs))
		return self
	}

	/// Add a end-of-line character to the stream
	@discardableResult
	@objc func endl() -> DSFAttributedStringStream {
		self.append("\n")
		return self
	}

	/// Add a tab character to the stream
	@discardableResult
	@objc func tab() -> DSFAttributedStringStream {
		self.append("\t")
		return self
	}

	#if os(macOS)

	/// Add an image at the current location
	@discardableResult
	@objc(appendImage:) func append(_ rhs: NSImage) -> DSFAttributedStringStream {
		self.append(rhs, rhs.size)
		return self
	}

	/// Add an image to the stream, sizing to the specified CGSize
	@discardableResult
	@objc(appendScaledImage::) func append(_ image: NSImage, _ size: CGSize) -> DSFAttributedStringStream {
		let attachment = NSTextAttachment()
		let flipped = NSImage(size: size, flipped: false, drawingHandler: { (rect: NSRect) -> Bool in
			NSGraphicsContext.current?.cgContext.translateBy(x: 0, y: size.height)
			NSGraphicsContext.current?.cgContext.scaleBy(x: 1, y: -1)
			image.draw(in: rect)
			return true
		})

		attachment.image = flipped
		self.text.append(NSAttributedString(attachment: attachment))
		return self
	}

	#elseif os(iOS) || os(tvOS)

	/// Add an image at the current location
	@discardableResult
	@objc(appendImage:) func append(_ rhs: UIImage) -> DSFAttributedStringStream {
		let attachment = NSTextAttachment()
		attachment.image = rhs
		attachment.bounds = CGRect(x: 0.0, y: 0.0, width: rhs.size.width, height: rhs.size.height)
		self.text.append(NSAttributedString(attachment: attachment))
		return self
	}

	#endif

}

// MARK: Setting and unsetting styles

extension DSFAttributedStringStream {

	@discardableResult
	@objc(setStyle::) public func set(_ key: NSAttributedString.Key, _ value: Any) -> DSFAttributedStringStream {
		self.add(key: key, value: value)
		return self
	}

	@discardableResult
	@objc(setStyles:) public func set(_ rhs: [NSAttributedString.Key: Any]) -> DSFAttributedStringStream {
		return self.add(rhs)
	}

	@discardableResult
	@objc(setShadow:) public func set(_ rhs: NSShadow) -> DSFAttributedStringStream {
		self.add(key: .shadow, value: rhs)
		return self
	}

	@discardableResult
	@objc(setParagraphStyle:) public func set(_ rhs: NSParagraphStyle) -> DSFAttributedStringStream {
		self.add(key: NSAttributedString.Key.paragraphStyle, value: rhs)
		return self
	}

	@discardableResult
	@objc(setFont:) public func set(_ rhs: FontSpecifier) -> DSFAttributedStringStream {
		self.add(key: NSAttributedString.Key.font, value: rhs)
		return self
	}

	@discardableResult
	@objc(setColor:) public func set(_ rhs: ColorSpecifier) -> DSFAttributedStringStream {
		self.add(key: NSAttributedString.Key.foregroundColor, value: rhs)
		return self
	}

	/// 'unset' (turn off) the specified attributes from the current location onwards
	@discardableResult
	@objc(unsetStyles:) public func unset(_ rhs: [NSAttributedString.Key: Any]) -> DSFAttributedStringStream {
		Array(rhs.keys).forEach { self.remove(key: $0) }
		return self
	}

	/// 'unset' (turn off) the specified attributed key from the current location onwards
	@discardableResult
	@objc(unsetStyle:) public func unset(_ rhs: NSAttributedString.Key) -> DSFAttributedStringStream {
		self.remove(key: rhs)
		return self
	}

	/// 'unset' (turn off) the specified attributed keys from the current location onwards
	@discardableResult
	@objc(unsetStyleArray:) public func unset(_ rhs: [NSAttributedString.Key]) -> DSFAttributedStringStream {
		rhs.forEach { self.remove(key: $0) }
		return self
	}

	/// 'unset' (turn off) all of the styles currently active from the current location onwards
	@discardableResult
	@objc public func unsetAll() -> DSFAttributedStringStream {
		self.removeAll()
		return self
	}
}

// MARK: Convenience methods

extension DSFAttributedStringStream {

	@discardableResult
	@objc public func link(url: URL, text: String? = nil) -> DSFAttributedStringStream {
		self.add(key: .link, value: url)
		if let text = text {
			self.append(text)
		}
		else {
			self.append("\(url)")
		}
		self.remove(key: .link)
		return self
	}

	@discardableResult
	@objc public func shadow(_ configureBlock: (NSShadow) -> Void) -> NSShadow {
		let obj = NSShadow()
		configureBlock(obj)
		self.add(key: .shadow, value: obj)
		return obj
	}

	@discardableResult
	@objc public func unsetShadow() -> DSFAttributedStringStream {
		self.remove(key: .shadow)
		return self
	}

}
