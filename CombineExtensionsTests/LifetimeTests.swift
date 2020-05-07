//
//  CombineExtensionsTests.swift
//  CombineExtensionsTests
//
//  Created by Vladimir Kazantsev on 22.04.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

import XCTest
import Combine
import CombineExtensions

class LifetimeTests: XCTestCase {

	var cancellable: AnyCancellable?

	func testPrefixDuringLifetime() {

		let lifetimeEndedExpectation = expectation( description: "Lifetime has ended" )
		let signalPassedExpectation = expectation( description: "Text signal has passed" )

		var lifetimeDummy: UILabel? = UILabel()

		cancellable =
			Empty<String, Never>( completeImmediately: false )
				.merge( with: Just<String>( "Test" ) )
				.prefix( during: Lifetime.of( lifetimeDummy! ))
				.handleEvents( receiveCancel: {
					XCTAssert( false, "Received unexpected cancel" )
				} )
				.sink( receiveCompletion: {
					if case .finished = $0 { lifetimeEndedExpectation.fulfill() }
					else { XCTAssert( false, "Received unexpected error" ) }
				}, receiveValue: { text in
					XCTAssertEqual( text, "Test" )
					signalPassedExpectation.fulfill()
				})

		lifetimeDummy = nil
		wait( for: [ signalPassedExpectation, lifetimeEndedExpectation ], timeout: 1 )
    }

	class TestSubject {

		var testString: String = ""

		let storeSubject = PassthroughSubject<String, Never>()

		init( lifetime: Lifetime ) {

			cancellable = storeSubject
				.prefix( during: lifetime )
				// This will strongly captures `self`.
				.assign( to: \.testString, on: self )
		}
		private var cancellable: AnyCancellable?
	}

	func testPrefixDuringLifetime2() {

		let ( lifetime, token ) = Lifetime.make()

		var testSubject: TestSubject? = TestSubject( lifetime: lifetime )
		weak var testWeakSubject = testSubject

		testSubject!.storeSubject.send( "Test" )
		XCTAssert( testSubject!.testString == "Test" )

		testSubject = nil
		// Retain cycle in `testSubject` should keep it alive.
		XCTAssertNotNil( testWeakSubject )

		// Ending lifetime should break retain cycle and release `testSubject`.
		token.cancel()
		XCTAssertNil( testWeakSubject )
	}
}
