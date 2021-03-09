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

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension AnyPublisher {

	/// Create a `Publisher` that will be controlled by sending events to an
	/// subscriber.
	///
	/// - parameters:
	///   - disposable: An optional disposable to associate with the signal, and
	///                 to be disposed of when the signal terminates.
	///
	/// - returns: A 2-tuple of the output end of the pipe as `AnyPublisher`,
	/// and the input end of the pipe as `AnyPublisher.Subscriber`.
	///
	/// - note: On `subscriber` deinit completion event sent to publisher.
	///
	static func pipe() -> ( publisher: AnyPublisher<Output, Failure>, subscriber: AnySubscriber<Output, Failure> ) {

		let subscriber = Publishers.PipePublisher<Output, Failure>.Subscriber()
		let publisher = Publishers.PipePublisher<Output, Failure>( subscriber: subscriber )

		return ( publisher.eraseToAnyPublisher(), AnySubscriber( subscriber ))
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers.PipePublisher {

	final class Subscriber: Combine.Subscriber {

		public func receive( subscription: Combine.Subscription ) {
			fatalError()
		}

		public func receive( _ input: Output ) -> Subscribers.Demand {
			subscriptions.forEach { $0.value?.send( input ) }
			return .unlimited
		}

		public func receive( completion: Subscribers.Completion<Failure> ) {
			subscriptions.forEach { $0.value?.send( completion: completion ) }
		}

		fileprivate init() {}
		deinit {
			receiveCompletion()
		}

		fileprivate func add( subscription:	SubscriptionType ) {
			subscriptions.append( WeakBox( subscription ) )
		}

		/// Holding weak list of subscribers of the `PipePublisher`.
		private struct WeakBox<Object: AnyObject> {
			weak var value: Object?
			init( _ value: Object ) { self.value = value }
		}
		private var subscriptions = [ WeakBox<SubscriptionType> ]()

		fileprivate typealias SubscriptionType =
			Publishers.PipePublisher<Output, Failure>.PipePublisherSubscription
	}
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers {

	struct PipePublisher<Output, Failure>: Publisher where Failure: Error {

		fileprivate init( subscriber: Subscriber ) {
			self.subscriber = subscriber
		}

		public func receive<SubscriberType>( subscriber: SubscriberType ) where
			SubscriberType : Combine.Subscriber,
			PipePublisher.Failure == SubscriberType.Failure,
			PipePublisher.Output == SubscriberType.Input {
				let subscription = PipePublisherSubscription( subscriber: AnySubscriber( subscriber ))
				self.subscriber?.add( subscription: subscription )
				subscriber.receive( subscription: subscription )
		}

		private weak var subscriber: Subscriber?
	}
}



@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers.PipePublisher {

	final class PipePublisherSubscription: Combine.Subscription {

		init( subscriber: AnySubscriber<Output, Failure> ) {
			self.subscriber = subscriber
		}

		public func request( _ demand: Subscribers.Demand ) {
			// Ignore demand.
		}

		public func cancel() {
			self.subscriber = nil
		}

		fileprivate func send( _ value: Output ) {
			_ = subscriber?.receive( value )
		}
		fileprivate func send( completion: Subscribers.Completion<Failure> ) {
			subscriber?.receive( completion: completion )
		}

		private var subscriber: AnySubscriber<Output, Failure>?
	}
}
