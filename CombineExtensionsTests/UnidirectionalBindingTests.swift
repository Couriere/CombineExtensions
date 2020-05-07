//
//  UnidirectionalBindingTests.swift
//  CombineExtensionsTests
//
//  Created by Vladimir Kazantsev on 23.04.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

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
