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
class AnyPublisherClosureTests: XCTestCase {

	enum _Error: Error {
		case sampleError
	}

	var cancellable: AnyCancellable?

	override func tearDown() {
		cancellable = nil
	}

	func testAsyncSuccess() {

		let asyncPublisher = AnyPublisher<Int, _Error> { sink, _ in

			DispatchQueue.global().asyncAfter( deadline: .now() + 0.5) {
				sink.send( 10 )
				sink.sendFinished()
			}
		}

		let valueExpectation = XCTestExpectation( description: "Success value received" )
		let completionExpectation = XCTestExpectation( description: "Completion signal received" )

		cancellable = asyncPublisher
			.sink { completion in
				switch completion {
				case .finished:
					completionExpectation.fulfill()
				case .failure:
					XCTFail( "Shouldn't get an error here" )
				}
			} receiveValue: {
				guard $0 == 10 else { XCTFail( "Wrong value sent" ); return }
				valueExpectation.fulfill()
			}

		wait( for: [ valueExpectation, completionExpectation ], timeout: 1, enforceOrder: true )
	}

	func testAsyncFail() {

		let asyncPublisher = AnyPublisher<Int, _Error> { sink, _ in

			DispatchQueue.global().asyncAfter( deadline: .now() + 0.5 ) {
				sink.send( .sampleError )
			}
		}

		let failureExpectation = XCTestExpectation( description: "Failure signal received" )

		cancellable = asyncPublisher
			.sink { completion in
				switch completion {
				case .finished:
					XCTFail( "Shouldn't get finished signal" )
				case .failure:
					failureExpectation.fulfill()
				}
			} receiveValue: { _ in
				XCTFail( "Shouldn't get a value" )
			}

		wait( for: [ failureExpectation ], timeout: 1 )
	}


	func testAsyncCancel() {

		let cancelExpectation = XCTestExpectation( description: "Cancel signal received" )

		let asyncPublisher = AnyPublisher<Int, _Error> { sink, lifetime in

			DispatchQueue.global().asyncAfter( deadline: .now() + 0.7 ) {
				if lifetime.hasEnded {
					cancelExpectation.fulfill()
				}
			}
		}

		cancellable = asyncPublisher
			.sink { _ in
				XCTFail( "Shouldn't get completion signal" )
			} receiveValue: { _ in
				XCTFail( "Shouldn't get a value" )
			}

		DispatchQueue.main.asyncAfter( deadline: .now() + 0.3 ) {
			self.cancellable = nil
		}

		wait( for: [ cancelExpectation ], timeout: 1 )
	}


	func testSyncSuccess() {

		let syncPublisher = AnyPublisher<Int, _Error> { sink, _ in
			sink.send( 10 )
			sink.sendFinished()
		}

		let valueExpectation = XCTestExpectation( description: "Success value received" )
		let completionExpectation = XCTestExpectation( description: "Completion signal received" )

		cancellable = syncPublisher
			.sink { completion in
				switch completion {
				case .finished:
					completionExpectation.fulfill()
				case .failure:
					XCTFail( "Shouldn't get an error here" )
				}
			} receiveValue: {
				guard $0 == 10 else { XCTFail( "Wrong value sent" ); return }
				valueExpectation.fulfill()
			}

		wait( for: [ valueExpectation, completionExpectation ], timeout: 1, enforceOrder: true )
	}
}
