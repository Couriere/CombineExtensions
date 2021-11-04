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

import Foundation

import XCTest
import Combine
import CombineExtensions

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class ActionTests: XCTestCase {

	let testError = NSError( domain: "ActionTests", code: -1, userInfo: nil )

	var executions: Int = 0
	var completions: Int = 0
	var values: [ Int ] = []
	var errors: [ Error ] = []
	var disabledErrors: [ Void ] = []

	var action: Action<Int, Int, Error>!
	var cancellables: Set<AnyCancellable> = []

	override func setUp() {
		cancellables = []

		executions = 0
		completions = 0
		values = []
		errors = []
		disabledErrors = []

		@MutableProperty var enabled: Bool = true

		action = Action( enabledIf: $enabled ) { [unowned self] parameter in
			AnyPublisher { sink, lifetime in
				self.executions += 1

				DispatchQueue.main.async {
					if parameter > 0 {
						sink.send( parameter * parameter )
						sink.send( completion: .finished )
					} else {
						sink.send( testError )
					}
				}
			}
		}

		action.values.sink { self.values.append( $0 ) }.store( in: &cancellables )
		action.errors.sink { self.errors.append( $0 ) }.store( in: &cancellables )
		action.disabledErrors.sink { self.disabledErrors.append( $0 ) }.store( in: &cancellables )
		action.executionObservables.sink { _ in self.completions += 1 }.store( in: &cancellables )
	}

	func testAfterCreationState() {
		XCTAssertEqual( executions, 0 )
		XCTAssertEqual( action.isEnabled.value, true )
		XCTAssertEqual( action.isExecuting.value, false )

		@MutableProperty var enabled = false
		let disabledAction = Action<Void, Int, Never>( enabledIf: $enabled ) {
			AnyPublisher( value: 0 )
		}

		XCTAssertEqual( disabledAction.isEnabled.value, false )
		XCTAssertEqual( disabledAction.isExecuting.value, false )
	}

	func testCreatingValue() {

		action.inputs.send( 2 )

		XCTAssertEqual( executions, 1 )
		XCTAssertEventually( values == [4] )
		XCTAssertEventually( completions == 1 )

		action.inputs.send( 4 )
		XCTAssertEventually( executions == 2 )
		XCTAssertEventually( values == [4,16] )
		XCTAssertEventually( completions == 2 )
	}

	func testFailure() {
		action.inputs.send( 5 )
		XCTAssertEqual( executions, 1 )
		XCTAssertEventually( values == [25] )
		XCTAssertEventually( completions == 1 )

		action.inputs.send( 0 )
		XCTAssertEqual( executions, 2 )
		XCTAssertEventually( values == [25] )
		XCTAssertEventually( errors.count == 1 )
		XCTAssertEventually( completions == 2 )
	}

	func testDisabledError() {

		let enabledExpectation = XCTestExpectation( description: "Action is Enabled again" )
		cancellables += action.isEnabled.sink { if $0 { enabledExpectation.fulfill() }}

		action.inputs.send( 1 )
		XCTAssertFalse( action.isEnabled.value )
		XCTAssertTrue( action.isExecuting.value )

		action.inputs.send( 5 )
		XCTAssertEqual( executions, 1 )
		XCTAssertEventually( values == [1], message: "\(values)" )
		XCTAssertEventually( completions == 2, message: "\(completions)" )
		XCTAssertEventually( errors.isEmpty )
		XCTAssertEqual( disabledErrors.count, 1 )

		wait( for: [ enabledExpectation ], timeout: 1 )
		XCTAssertTrue( action.isEnabled.value )
		XCTAssertFalse( action.isExecuting.value )

		action.inputs.send( 6 )
		XCTAssertEqual( executions, 2 )
		XCTAssertEventually( values == [1, 36] )
	}

	func testApplySyncWork() {

		action = Action { input in
			[ input * 2, ( input + 1 ) * 2 ].publisher
				.setFailureType( to: Error.self )
		}

		let firstValue1Expectation = XCTestExpectation()
		let secondValue1Expectation = XCTestExpectation()
		let completion1Expectation = XCTestExpectation()

		let firstValue2Expectation = XCTestExpectation()
		let secondValue2Expectation = XCTestExpectation()
		let completion2Expectation = XCTestExpectation()

		cancellables += action.apply( 5 )
			.sink { completion in
				switch completion {
				case .finished: completion1Expectation.fulfill()
				case .failure: XCTFail( "Unexpected error received." )
				}
			} receiveValue: {
				switch $0 {
				case 10: firstValue1Expectation.fulfill()
				case 12: secondValue1Expectation.fulfill()
				default: XCTFail( "Wrong value - \( $0 )" )
				}
			}

		cancellables += action.apply( 10 )
			.sink { completion in
				switch completion {
				case .finished: completion2Expectation.fulfill()
				case .failure: XCTFail( "Unexpected error received." )
				}
			} receiveValue: {
				switch $0 {
				case 20: firstValue2Expectation.fulfill()
				case 22: secondValue2Expectation.fulfill()
				default: XCTFail( "Wrong value - \( $0 )" )
				}
			}

		wait( for: [
			firstValue1Expectation, secondValue1Expectation, completion1Expectation,
			firstValue2Expectation, secondValue2Expectation, completion2Expectation,
		], timeout: 1, enforceOrder: true )
	}


	func testApplyAsyncWork() {

		action = Action { input in
			[ input * 2, ( input + 1 ) * 2 ].publisher
				.delay( for: 0.3, scheduler: DispatchQueue.global() )
				.setFailureType( to: Error.self )
		}

		let firstValueExpectation = XCTestExpectation( description: "firstValue" )
		let secondValueExpectation = XCTestExpectation( description: "secondValue" )
		let completionExpectation = XCTestExpectation( description: "Completion" )

		let notEnabledFailureExpectation = XCTestExpectation( description: "Not Enabled" )

		cancellables += action.apply( 5 )
			.sink { completion in
				switch completion {
				case .finished: completionExpectation.fulfill()
				case .failure: XCTFail( "Unexpected error received." )
				}
			} receiveValue: {
				switch $0 {
				case 10: firstValueExpectation.fulfill()
				case 12: secondValueExpectation.fulfill()
				default: XCTFail( "Wrong value - \( $0 )" )
				}
			}

			self.cancellables += self.action.apply( 10 )
				.sink { completion in
					switch completion {
					case .finished: XCTFail( "Unexpected finished event." )
					case .failure( let error ):
						switch error {
						case .disabled: notEnabledFailureExpectation.fulfill()
						case .failed: XCTFail( "Unexpected error received." )
						}
					}
				} receiveValue: {
					XCTFail( "Unexpected value received: \( $0 )" )
				}

			self.wait( for: [
				notEnabledFailureExpectation, firstValueExpectation, secondValueExpectation, completionExpectation,
			], timeout: 1, enforceOrder: true )
	}

	func testReplay() {

		let firstSinkExpectation = XCTestExpectation()
		let secondSinkExpectation = XCTestExpectation()

		var firstSinkValues: [ Int ] = []
		var secondSinkValues: [ Int ] = []

		let randomPublisher = (1...5).publisher
			.delay( for: 0.1, scheduler: DispatchQueue.main )
			.map { _ in return Int.random( in: 0...100 ) }
			.replayLazily()



		cancellables += randomPublisher
			.sink { _ in
				firstSinkExpectation.fulfill()
			} receiveValue: {
				firstSinkValues.append( $0 )
			}

		DispatchQueue.global().asyncAfter( deadline: .now() + 0.3 ) {
			self.cancellables += randomPublisher
				.sink { _ in
					secondSinkExpectation.fulfill()
				} receiveValue: {
					secondSinkValues.append( $0 )
				}
		}

		wait( for: [ firstSinkExpectation, secondSinkExpectation ], timeout: 1 )
		XCTAssertEqual( firstSinkValues, secondSinkValues )
	}
}

extension XCTest {
	func XCTAssertEventually(
		_ test: @autoclosure () -> Bool,
		timeout: TimeInterval = 1.0,
		message: String = ""
	) {

		let runLoop = RunLoop.current
		let timeoutDate = Date(timeIntervalSinceNow: timeout)
		repeat {
			if test() { return }
			runLoop.run( until: Date( timeIntervalSinceNow: 0.01 ))
		} while Date().compare( timeoutDate ) == .orderedAscending
		// 4
		XCTFail( message )
	}
}
