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

class UnidirectionalBindingTests: XCTestCase {

	let ( lifetime, token ) = Lifetime.make()

	func testBindingDataFlow() {

		var value: Int = 0
		let bindingTarget = BindingTarget( lifetime: lifetime, action: { value = $0 } )

		XCTAssert( value == 0 )
		bindingTarget <~ CurrentValueSubject<Int, Never>( -1 )
		XCTAssert( value == -1 )
	}

	func testBindingFromTheSameQueue() {
		var value: Int = 0
		let valueMinusOneExpectation = expectation( description: "Expecting value of -1" )
		let valueTwoExpectation = expectation( description: "Expecting value of 2" )

		let bindingTarget = BindingTarget<Int>( on: DispatchQueue.main, lifetime: lifetime ) {
			value = $0
			switch $0 {
			case -1: valueMinusOneExpectation.fulfill()
			case 2: valueTwoExpectation.fulfill()
			default: XCTAssert( false, "Unknown value passed" )
			}
		}


		XCTAssert( value == 0 )
		let subject = CurrentValueSubject<Int, Never>( -1 )
		bindingTarget <~ subject
		subject.value = 2

		wait( for: [ valueMinusOneExpectation, valueTwoExpectation ], timeout: 1, enforceOrder: true )
	}

	func testSyncQueueDeadlock() {
		var value: Int = 0
		let valueMinusOneExpectation = expectation( description: "Expecting value of -1" )

		let bindingTarget = BindingTarget<Int>( on: DispatchQueue.main, lifetime: lifetime ) {
			value = $0
			XCTAssert( $0 == -1, "Unknown value passed" )
			valueMinusOneExpectation.fulfill()
		}

		let queue = DispatchQueue( label: #file )

		let subject = CurrentValueSubject<Int, Never>( -1 )

		queue.sync {
			_ = bindingTarget <~ subject
		}

		wait( for: [ valueMinusOneExpectation ], timeout: 1 )
		XCTAssert( value == -1 )
	}
}
