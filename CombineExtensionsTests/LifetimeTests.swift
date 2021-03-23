//
//  -=Combine Extensions=-
//
// MIT License
//
// Copyright (c) 2019-present Vladimir Kazantsev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest
import Combine
import CombineExtensions

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class LifetimeTests: XCTestCase {

	var cancellable: AnyCancellable?

	class LifetimeDummy {}

	func testPrefixDuringLifetime() {

		let lifetimeEndedExpectation = expectation( description: "Lifetime has ended" )
		let signalPassedExpectation = expectation( description: "Text signal has passed" )

		var lifetimeDummy: LifetimeDummy? = LifetimeDummy()

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

	func testLifetimeRetainCycle() {

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
