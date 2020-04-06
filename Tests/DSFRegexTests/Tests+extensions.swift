//
//  File.swift
//  
//
//  Created by Darren Ford on 6/4/20.
//

import Foundation
import XCTest

func performTest(closure: () throws -> Void) {
	do {
		try closure()
	} catch {
		XCTFail("Unexpected error thrown: \(error)")
	}
}

func scenario(_ what: String, _ block: () throws -> Void) throws {
	XCTAssertNoThrow(try block(), what)
}
