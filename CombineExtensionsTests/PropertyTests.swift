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

class PropertyTests: XCTestCase {

	var cancellable: AnyCancellable?

	func testPrefixConstantProperty() {
		let constantProperty = Property<String>( value: "constanT" )
		XCTAssertEqual( constantProperty.value, "constanT" )

		let expectation = XCTestExpectation()
		cancellable = constantProperty
			.sink { _ in
				XCTFail( "Unexpected completion." )
			} receiveValue: {
				XCTAssertEqual( $0, "constanT" )
				expectation.fulfill()
			}

		wait( for: [ expectation ], timeout: 0.1 )
	}

	func testExistentialPropertyWithCurrentValueSubject() {

		let subject = CurrentValueSubject<String, Never>( "Subject initial value" )
		let existentialProperty = Property( subject )

		let initialExpectation = XCTestExpectation()
		let finalExpectation = XCTestExpectation()
		cancellable = existentialProperty
			.sink { _ in
				XCTFail( "Unexpected completion." )
			} receiveValue: {
				switch $0 {
				case "Subject initial value": initialExpectation.fulfill()
				case "Subject final value": finalExpectation.fulfill()
				default: XCTFail( "Unknown value" )
				}
			}

		XCTAssertEqual( existentialProperty.value, "Subject initial value" )
		subject.value = "Subject final value"
		XCTAssertEqual( existentialProperty.value, "Subject final value" )

		wait( for: [ initialExpectation, finalExpectation ], timeout: 0.1, enforceOrder: true )
	}

	func testExistentialPropertyWithMutableProperty() {

		let mutableProperty = MutableProperty<String>( "Subject initial value" )
		let existentialProperty = Property( mutableProperty )

		let initialExpectation = XCTestExpectation()
		let finalExpectation = XCTestExpectation()
		cancellable = existentialProperty
			.sink { _ in
				XCTFail( "Unexpected completion." )
			} receiveValue: {
				switch $0 {
				case "Subject initial value": initialExpectation.fulfill()
				case "Subject final value": finalExpectation.fulfill()
				default: XCTFail( "Unknown value" )
				}
			}

		XCTAssertEqual( existentialProperty.value, "Subject initial value" )
		mutableProperty.value = "Subject final value"
		XCTAssertEqual( existentialProperty.value, "Subject final value" )

		wait( for: [ initialExpectation, finalExpectation ], timeout: 0.1, enforceOrder: true )
	}

	func testComposedProperty() {

		let subject = PassthroughSubject<Int, Never>()
		let composedProperty = Property<Int>( initial: -101, then: subject )

		let initialExpectation = XCTestExpectation()
		let finalExpectation = XCTestExpectation()
		cancellable = composedProperty
			.sink { _ in
				XCTFail( "Unexpected completion." )
			} receiveValue: {
				switch $0 {
				case -101: initialExpectation.fulfill()
				case 101: finalExpectation.fulfill()
				default: XCTFail( "Unknown value" )
				}
			}

		XCTAssertEqual( composedProperty.value, -101 )
		subject.send( 101 )
		XCTAssertEqual( composedProperty.value, 101 )

		wait( for: [ initialExpectation, finalExpectation ], timeout: 0.1, enforceOrder: true )
	}

	func testCodable() {
		struct CodableStruct: Codable {
			@Property var property: String
		}

		let jsonData = "{\"property\":\"Test\"}".data( using: .utf8 )!
		let loadedStruct = try! JSONDecoder().decode( CodableStruct.self, from: jsonData )
		XCTAssertEqual( loadedStruct.property, "Test" )
		let encodedStruct = try! JSONEncoder().encode( loadedStruct )
		XCTAssertEqual( jsonData, encodedStruct )
	}
}
