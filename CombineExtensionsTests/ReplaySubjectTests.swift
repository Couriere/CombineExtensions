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
class ReplaySubjectTests: XCTestCase {

	var values1: [ Int ] = []
	var didComplete: Bool = false
	let subject = ReplaySubject<Int, Never>()

	var cancellable: Set<AnyCancellable> = []


	func testSubscribers() {
		var values2: [ Int ] = []
		var values3: [ Int ] = []
		var didComplete2: Bool = false

		cancellable += subject
			.sink { completion in
				if completion.isCompleted { self.didComplete = true }
			} receiveValue: {
				self.values1.append( $0 )
			}

		XCTAssertEqual( values1, [] )
		subject.send( 10 )

		cancellable += subject.sink( receiveValue: { values2.append( $0 ) })
		XCTAssertEqual( values1, [ 10 ] )
		XCTAssertEqual( values2, values1 )

		subject.send( 20 )
		XCTAssertEqual( values1, [ 10, 20 ] )
		XCTAssertEqual( values2, values1 )
		XCTAssertFalse( didComplete )

		subject.send( completion: .finished )
		cancellable += subject.sink { _ in didComplete2 = true } receiveValue: { values3.append( $0 ) }

		XCTAssertEqual( values1, [ 10, 20 ] )
		XCTAssertEqual( values2, values1 )
		XCTAssertEqual( values3, values1 )

		XCTAssertTrue( didComplete )
		XCTAssertTrue( didComplete2 )
	}

	func testSendValuesWithoutSubscriber() {

		subject.send( 0 )
		subject.send( 2 )
		XCTAssert( values1 == [] )
		XCTAssertFalse( didComplete )

		cancellable += subject
			.sink { completion in
				if completion.isCompleted { self.didComplete = true }
			} receiveValue: {
				self.values1.append( $0 )
			}

		XCTAssertEqual( values1, [ 0, 2 ] )
		XCTAssertFalse( didComplete )
	}


	func testSendCompletionWithoutSubscriber() {

		subject.send( 1 )
		subject.send( 3 )
		XCTAssertEqual( values1, [] )
		subject.send( completion: .finished )
		XCTAssertFalse( didComplete )

		cancellable += subject
			.sink { completion in
				if completion.isCompleted { self.didComplete = true }
			} receiveValue: {
				self.values1.append( $0 )
			}

		XCTAssertEqual( values1, [ 1, 3 ] )
		XCTAssertTrue( didComplete )
	}


	weak var weakSink: Subscribers.Sink<Int, Never>?
	func testCancelSubscriber() {
		var sink: Subscribers.Sink<Int, Never>? = Subscribers.Sink { completion in
			if completion.isCompleted { self.didComplete = true }
		} receiveValue: {
			self.values1.append( $0 )
		}
		weakSink = sink

		subject.receive( subscriber: sink! )
		cancellable += AnyCancellable( sink! )
		sink = nil

		XCTAssertNotNil( weakSink )

		cancellable = []

		XCTAssertNil( weakSink )
		XCTAssertFalse( didComplete )
	}

	func testCompleteSubscriber() {
		var sink: Subscribers.Sink<Int, Never>? = Subscribers.Sink { completion in
			if completion.isCompleted { self.didComplete = true }
		} receiveValue: {
			self.values1.append( $0 )
		}
		weakSink = sink

		subject.receive( subscriber: sink! )
		cancellable += AnyCancellable( sink! )
		sink = nil

		XCTAssertNotNil( weakSink )

		subject.send( completion: .finished )
		XCTAssertNotNil( weakSink )
		XCTAssertTrue( didComplete )
		cancellable = []
		XCTAssertNil( weakSink )
	}
}
