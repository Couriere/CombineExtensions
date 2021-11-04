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
import Combine

/// A publisher that exposes a method for outside callers to publish elements.
///
/// Each notification is broadcasted to all subscribed and future subscribers, subject to buffer trimming policies.
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
final public class ReplaySubject<Output, Failure: Error>: Subject {

	private var buffer: [ Output ] = []
	private let bufferSize: Int
	private var lock = NSRecursiveLock()

	private var subscriptions = [ReplaySubjectSubscription<Output, Failure>]()
	private var completion: Subscribers.Completion<Failure>?


	public init( bufferSize: Int = 0 ) {
		self.bufferSize = bufferSize
	}

	/// Sends a value to the subscriber.
	///
	/// - Parameter value: The value to send.
	public func send( _ value: Output ) {
		lock.lock(); defer { lock.unlock() }
		buffer.append( value )
		if bufferSize > 0 { buffer = buffer.suffix( bufferSize ) }
		subscriptions.forEach { $0.receive( value ) }
	}

	/// Sends a completion signal to the subscriber.
	///
	/// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
	public func send( completion: Subscribers.Completion<Failure> ) {
		lock.lock(); defer { lock.unlock() }
		subscriptions.forEach { $0.receive( completion: completion ) }
		self.completion = completion
	}

	/// Sends a subscription to the subscriber.
	///
	/// This call provides the ``Subject`` an opportunity to establish demand for any new upstream subscriptions.
	///
	/// - Parameter subscription: The subscription instance through which the subscriber can request elements.
	public func send( subscription: Subscription ) {
		lock.lock(); defer { lock.unlock() }
		subscription.request( .unlimited )
	}

}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension ReplaySubject {

	/// Attaches the specified subscriber to this publisher.
	///
	/// Implementations of ``Publisher`` must implement this method.
	///
	/// The provided implementation of ``Publisher/subscribe(_:)-4u8kn``calls this method.
	///
	/// - Parameter subscriber: The subscriber to attach to this ``Publisher``, after which it can receive values.
	public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
		lock.lock(); defer { lock.unlock() }

		let subscription = ReplaySubjectSubscription<Output, Failure>( downstream: AnySubscriber( subscriber ))
		subscriber.receive( subscription: subscription )
		subscriptions.append( subscription )
		subscription.replay( buffer, completion: completion )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
private extension ReplaySubject {

	final class ReplaySubjectSubscription<Output, Failure: Error>: Subscription {

		private var downstream: AnySubscriber<Output, Failure>?
		private var demand: Subscribers.Demand = .none

		init( downstream: AnySubscriber<Output, Failure> ) {
			self.downstream = downstream
		}

		func request( _ newDemand: Subscribers.Demand ) {
			demand += newDemand
		}

		func cancel() {
			downstream = nil
		}

		func receive( _ value: Output ) {
			guard let downstream = downstream, demand > 0 else { return }

			demand += downstream.receive( value )
			demand -= 1
		}

		func receive( completion: Subscribers.Completion<Failure> ) {
			guard let downstream = downstream else { return }
			cancel()
			downstream.receive( completion: completion )
		}

		func replay( _ values: [ Output ], completion: Subscribers.Completion<Failure>? ) {
			guard let downstream = downstream else { return }
			values.forEach { receive( $0 ) }
			if let completion = completion { downstream.receive( completion: completion ) }
		}
	}
}
