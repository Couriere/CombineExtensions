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
class CurrentValueSubjectPropertyTests: XCTestCase {

	var cancellable: AnyCancellable?

	@MutableProperty var mutableProperty: Int = -101

	func testCurrentValueSubjectProperty() {

		let subject = PassthroughSubject<Int, Never>()

		let initialExpectation = XCTestExpectation()
		let midExpectation = XCTestExpectation()
		let finalExpectation = XCTestExpectation()

		$mutableProperty <~ subject

		cancellable = $mutableProperty
			.sink { _ in
				XCTFail( "Unexpected completion." )
			} receiveValue: {
				switch $0 {
				case -101: initialExpectation.fulfill()
				case 0: midExpectation.fulfill()
				case 101: finalExpectation.fulfill()
				default: XCTFail( "Unknown value" )
				}
			}

		XCTAssertEqual( mutableProperty, -101 )
		mutableProperty = 0
		XCTAssertEqual( mutableProperty, 0 )
		subject.send( 101 )
		XCTAssertEqual( mutableProperty, 101 )

		wait( for: [ initialExpectation, midExpectation, finalExpectation ], timeout: 0.1, enforceOrder: true )
	}

	func testCurrentValueSubjectPropertyLifetime() {
		var mutableProperty: MutableProperty<String>? = MutableProperty( "Test" )
		weak var weakMutableProperty = mutableProperty
		let subject = CurrentValueSubject<String, Never>( "In progress" )

		let canceledExpectation = XCTestExpectation()

		mutableProperty!.projectedValue <~ subject
			.handleEvents( receiveCancel: { canceledExpectation.fulfill() })

		mutableProperty = nil

		XCTAssertNil( weakMutableProperty )
		wait( for: [ canceledExpectation ], timeout: 0.2 )
	}

	func testCodable() {
		struct CodableStruct: Codable {
			@MutableProperty var property: String
		}

		let jsonData = "{\"property\":\"Test\"}".data( using: .utf8 )!
		let loadedStruct = try! JSONDecoder().decode( CodableStruct.self, from: jsonData )
		XCTAssertEqual( loadedStruct.property, "Test" )
		loadedStruct.property = "Changed"
		let encodedStruct = try! JSONEncoder().encode( loadedStruct )
		XCTAssertEqual( "{\"property\":\"Changed\"}", String( data: encodedStruct, encoding: .utf8 ))
	}
}
